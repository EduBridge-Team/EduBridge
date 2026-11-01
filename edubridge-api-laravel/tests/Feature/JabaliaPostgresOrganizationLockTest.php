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
}
