<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use PDO;
use PDOException;
use Tests\TestCase;

class JabaliaPostgresOrganizationLockTest extends TestCase
{
    public function test_two_postgres_connections_serialize_jabalia_organization_writes(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            $this->markTestSkipped('PostgreSQL-specific row locking test.');
        }

        // CI runs this only against its disposable migrated PostgreSQL database.
        Artisan::call('migrate:fresh', ['--force' => true]);
        $organizationId = DB::table('organizations')->insertGetId([
            'name' => 'Jabalia lock integration', 'slug' => 'jabalia-lock-test',
        ]);

        $config = config('database.connections.pgsql');
        $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s',
            $config['host'] ?? '127.0.0.1', $config['port'] ?? 5432, $config['database']);
        $second = new PDO($dsn, $config['username'], $config['password'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ]);

        DB::beginTransaction();
        try {
            // This is the row lock shared by timetable writes and teacher transfers.
            DB::table('organizations')->where('id', $organizationId)->lockForUpdate()->first();

            $second->beginTransaction();
            try {
                $second->exec("SET LOCAL lock_timeout = '250ms'");
                try {
                    $statement = $second->prepare('SELECT id FROM organizations WHERE id = ? FOR UPDATE');
                    $statement->execute([$organizationId]);
                    $this->fail('A concurrent writer bypassed the organization row lock.');
                } catch (PDOException $exception) {
                    $this->assertSame('55P03', $exception->getCode(), 'Expected PostgreSQL lock_not_available.');
                }
            } finally {
                if ($second->inTransaction()) $second->rollBack();
            }
        } finally {
            DB::rollBack();
        }

        // After the first transaction releases the lock, a second writer proceeds.
        $second->beginTransaction();
        try {
            $statement = $second->prepare('SELECT id FROM organizations WHERE id = ? FOR UPDATE');
            $statement->execute([$organizationId]);
            $this->assertSame($organizationId, (int) $statement->fetchColumn());
        } finally {
            $second->rollBack();
        }
    }
    public function test_transfer_assignment_removal_is_visible_to_waiting_timetable_writer(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            $this->markTestSkipped('Requires PostgreSQL.');
        }

        Artisan::call('migrate:fresh', ['--force' => true]);
        $organizationId = DB::table('organizations')->insertGetId([
            'name' => 'Jabalia concurrency', 'slug' => 'jabalia',
        ]);
        $teacherId = DB::table('users')->insertGetId([
            'name' => 'Concurrency teacher', 'email' => 'jabalia-lock-teacher@example.org',
            'password' => 'unused', 'role' => 'teacher',
        ]);
        $schoolId = DB::table('schools')->insertGetId([
            'organization_id' => $organizationId, 'name' => 'Source school', 'slug' => 'source',
        ]);
        $yearId = DB::table('academic_years')->insertGetId([
            'school_id' => $schoolId, 'name' => '2026/27',
            'starts_on' => '2026-09-01', 'ends_on' => '2027-06-30',
        ]);
        $gradeId = DB::table('grades')->insertGetId([
            'school_id' => $schoolId, 'name' => 'Grade 2',
        ]);
        $sectionId = DB::table('sections')->insertGetId([
            'grade_id' => $gradeId, 'academic_year_id' => $yearId, 'name' => 'A',
        ]);
        $subjectId = DB::table('subjects')->insertGetId([
            'school_id' => $schoolId, 'name' => 'Arabic',
        ]);
        DB::table('teacher_assignments')->insert([
            'teacher_id' => $teacherId, 'section_id' => $sectionId, 'subject_id' => $subjectId,
        ]);

        $config = config('database.connections.pgsql');
        $second = new PDO(sprintf('pgsql:host=%s;port=%s;dbname=%s',
            $config['host'] ?? '127.0.0.1', $config['port'] ?? 5432, $config['database']),
            $config['username'], $config['password'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

        // Transfer transaction owns the organization lock while removing the assignment.
        DB::beginTransaction();
        try {
            DB::table('organizations')->where('id', $organizationId)->lockForUpdate()->first();
            DB::table('teacher_assignments')->where('teacher_id', $teacherId)->delete();

            // The timetable writer cannot acquire the same lock while transfer is pending.
            $second->beginTransaction();
            try {
                $second->exec("SET LOCAL lock_timeout = '250ms'");
                try {
                    $lock = $second->prepare('SELECT id FROM organizations WHERE id = ? FOR UPDATE');
                    $lock->execute([$organizationId]);
                    $this->fail('Timetable writer bypassed transfer lock.');
                } catch (PDOException $exception) {
                    $this->assertSame('55P03', $exception->getCode());
                }
            } finally {
                if ($second->inTransaction()) $second->rollBack();
            }
            DB::commit();
        } catch (\Throwable $exception) {
            if (DB::transactionLevel() > 0) DB::rollBack();
            throw $exception;
        }

        // Once transfer commits, the waiting writer can lock but sees no assignment.
        $second->beginTransaction();
        try {
            $lock = $second->prepare('SELECT id FROM organizations WHERE id = ? FOR UPDATE');
            $lock->execute([$organizationId]);
            $assignment = $second->prepare(
                'SELECT COUNT(*) FROM teacher_assignments WHERE teacher_id = ? AND section_id = ? AND subject_id = ?'
            );
            $assignment->execute([$teacherId, $sectionId, $subjectId]);
            $this->assertSame(0, (int) $assignment->fetchColumn());
        } finally {
            $second->rollBack();
        }
    }

}
