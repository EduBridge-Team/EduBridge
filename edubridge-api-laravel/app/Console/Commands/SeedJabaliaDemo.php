<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use RuntimeException;

class SeedJabaliaDemo extends Command
{
    protected $signature = 'institutions:seed-jabalia-demo
        {--apply : Write the synthetic fixture; without this option the command is a dry-run}
        {--confirm-production : Explicitly acknowledge writes to the current production database}
        {--confirm-organization= : Must be jabalia}
        {--confirm-school= : Exact school ID to seed}
        {--confirm-database= : Exact current PostgreSQL database name}
        {--archive-legacy-fixtures : Reversibly label and deactivate the known pre-existing test setup}';

    protected $description = 'Create an idempotent, clearly labelled synthetic Jabalia school fixture in the existing Jabalia database.';

    private const YEAR_NAME = 'DEMO-2026/2027';
    private const ORG_DOMAIN = 'jabalia.edubridge';
    private const SCHOOL_DOMAIN = 'jabalia-demo.edubridge';
    private const FIXTURE_DATE = '2026-11-20';

    public function handle(): int
    {
        try {
            $database = DB::connection()->getDatabaseName();
            if (DB::connection()->getDriverName() !== 'pgsql') {
                throw new RuntimeException('Refusing to seed: Jabalia production fixtures require PostgreSQL.');
            }
            if (!is_string($this->option('confirm-database'))
                || $this->option('confirm-database') !== $database) {
                throw new RuntimeException("Database confirmation mismatch. Current database is '{$database}'. Pass --confirm-database with this exact value.");
            }
            if ($this->option('confirm-organization') !== 'jabalia') {
                throw new RuntimeException('Pass --confirm-organization=jabalia.');
            }

            $schoolId = filter_var($this->option('confirm-school'), FILTER_VALIDATE_INT);
            if (!$schoolId || $schoolId < 1) {
                throw new RuntimeException('Pass the exact school ID with --confirm-school.');
            }

            $organization = DB::table('organizations')->where('slug', 'jabalia')->first();
            if (!$organization || !$organization->is_active) {
                throw new RuntimeException('The active Jabalia organization was not found.');
            }
            $school = DB::table('schools')->where('id', $schoolId)
                ->where('organization_id', $organization->id)->where('is_active', true)->first();
            if (!$school) {
                throw new RuntimeException('The confirmed school does not belong to the active Jabalia organization.');
            }

            if ($this->option('apply') && config('app.env') === 'production'
                && !$this->option('confirm-production')) {
                throw new RuntimeException('Production writes require --confirm-production.');
            }
            if ($this->option('apply') && strtolower((string) (getenv('JABALIA_DEMO_SEED_ENABLED') ?: env('JABALIA_DEMO_SEED_ENABLED', ''))) !== 'true') {
                throw new RuntimeException('Production fixture writes are disabled. Set JABALIA_DEMO_SEED_ENABLED=true for this command invocation.');
            }

            $this->assertRequiredSchema();
            $this->assertReservedDomains($organization, $school);
            $this->assertNoConflictingDirector($school);

            $this->newLine();
            $this->info('Jabalia synthetic fixture preflight');
            $this->line('Organization: jabalia (#'.$organization->id.')');
            $this->line('School: '.$school->name.' (#'.$school->id.')');
            $this->line('Database: '.$database);
            $this->line('Mode: '.($this->option('apply') ? 'APPLY' : 'DRY RUN'));
            $this->line('Legacy test archive: '.($this->option('archive-legacy-fixtures') ? 'enabled (reversible labels/deactivation only)' : 'disabled'));
            $this->line('Planned dataset: 1 academic year, 2 terms, 2 grades, 5 subjects, 4 sections, 5 teachers, 4 parents, 8 enrolled students, 1 pending intake request, 20 teacher assignments, 20 subject quotas, 48 timetable entries, 4 daily attendance sessions, 8 attendance records, 10 draft curriculum books and lessons.');
            $this->line('No medical files, identity scans, signed contracts, real contact details, external AI calls or real sign-language claims will be created.');

            if (!$this->option('apply')) {
                $this->comment('Dry run only. No database rows were changed.');
                $this->comment('After verifying a PostgreSQL backup, run the production wrapper deploy/jabalia-demo-seed-production.sh.');
                return self::SUCCESS;
            }

            $password = (string) (getenv('JABALIA_DEMO_PASSWORD') ?: env('JABALIA_DEMO_PASSWORD', ''));
            if (strlen($password) < 20) {
                throw new RuntimeException('JABALIA_DEMO_PASSWORD must be supplied at invocation time and contain at least 20 characters.');
            }

            $result = DB::transaction(function () use ($organization, $school, $schoolId, $password) {
                DB::table('organizations')->where('id', $organization->id)->lockForUpdate()->first();
                DB::table('schools')->where('id', $schoolId)->lockForUpdate()->first();

                if ($this->option('archive-legacy-fixtures')) {
                    $this->archiveLegacyFixtures($schoolId);
                }

                DB::table('academic_years')->where('school_id', $schoolId)
                    ->where('is_current', true)->update(['is_current' => false, 'updated_at' => now()]);

                $yearId = $this->ensureAcademicYear($schoolId);
                $this->ensureTerms($yearId);

                $gradeIds = [
                    $this->ensureGrade($schoolId, '[DEMO] الصف الأول', 'DEMO-G1', 1),
                    $this->ensureGrade($schoolId, '[DEMO] الصف الإعدادي', 'DEMO-G7', 7),
                ];

                $subjectDefinitions = [
                    ['name' => '[DEMO] اللغة العربية', 'code' => 'DEMO-AR', 'quota' => 4, 'teacher' => 'demo.teacher.ar', 'lesson' => 'مهارات القراءة والفهم'],
                    ['name' => '[DEMO] الرياضيات', 'code' => 'DEMO-MA', 'quota' => 4, 'teacher' => 'demo.teacher.math', 'lesson' => 'القيمة المكانية للأعداد'],
                    ['name' => '[DEMO] العلوم', 'code' => 'DEMO-SC', 'quota' => 1, 'teacher' => 'demo.teacher.science', 'lesson' => 'الملاحظة والتصنيف'],
                    ['name' => '[DEMO] الدراسات الاجتماعية', 'code' => 'DEMO-SS', 'quota' => 1, 'teacher' => 'demo.teacher.social', 'lesson' => 'المجتمع المحلي'],
                    ['name' => '[DEMO] اللغة الإنجليزية', 'code' => 'DEMO-EN', 'quota' => 2, 'teacher' => 'demo.teacher.en', 'lesson' => 'Everyday words'],
                ];
                $subjectIds = [];
                foreach ($subjectDefinitions as $definition) {
                    $subjectIds[$definition['code']] = $this->ensureSubject(
                        $schoolId, $definition['name'], $definition['code']
                    );
                }

                $sectionIds = [];
                foreach ($gradeIds as $gradeId) {
                    foreach (['[DEMO] أ', '[DEMO] ب'] as $sectionName) {
                        $sectionIds[] = $this->ensureSection($gradeId, $yearId, $sectionName);
                    }
                }

                $adminId = $this->ensureUser(
                    'demo.admin@example.test', '[DEMO] مدير المؤسسة', 'institution', $password
                );
                $this->ensureOrganizationMembership((int) $organization->id, $adminId, 'owner');

                $directorId = $this->ensureUser(
                    'demo.director@example.test', '[DEMO] مدير المدرسة', 'school_director', $password
                );
                $this->ensureDirector($schoolId, (int) $organization->id, $adminId, $directorId);

                $teacherIds = [];
                foreach ($subjectDefinitions as $definition) {
                    $username = $definition['teacher'];
                    $email = $username.'@'.self::ORG_DOMAIN;
                    $teacherId = $this->ensureUser(
                        $email, '[DEMO] '.$this->teacherDisplayName($definition['code']), 'teacher', $password
                    );
                    $this->ensureOrganizationMembership((int) $organization->id, $teacherId, 'teacher');
                    $this->ensureInstitutionTeacherIdentity((int) $organization->id, $teacherId, $username, $adminId);
                    $this->ensureTeacherProfile((int) $organization->id, $teacherId, $definition['code']);
                    $teacherIds[$definition['code']] = $teacherId;
                }

                $parents = [];
                for ($index = 1; $index <= 4; $index++) {
                    $parents[$index] = $this->ensureUser(
                        sprintf('demo.parent.%02d@example.test', $index),
                        sprintf('[DEMO] ولي الأمر %02d', $index),
                        'parent',
                        $password
                    );
                }

                $staffId = $this->ensureUser(
                    'demo.staff01@'.self::SCHOOL_DOMAIN, '[DEMO] موظف المدرسة', 'staff', $password
                );
                $this->ensureSchoolIdentity($schoolId, $staffId, 'demo.staff01');

                $studentRows = [];
                $studentIndex = 0;
                foreach ($sectionIds as $sectionOffset => $sectionId) {
                    for ($withinSection = 1; $withinSection <= 2; $withinSection++) {
                        $studentIndex++;
                        $username = sprintf('demo.student.%02d', $studentIndex);
                        $parentIndex = (int) ceil($studentIndex / 2);
                        $childId = $this->ensureChild(
                            (int) $organization->id,
                            sprintf('[DEMO] الطالب %02d', $studentIndex)
                        );
                        $studentId = $this->ensureUser(
                            $username.'@'.self::SCHOOL_DOMAIN,
                            sprintf('[DEMO] الطالب %02d', $studentIndex),
                            'student',
                            $password
                        );
                        $this->ensureSchoolIdentity($schoolId, $studentId, $username);
                        $this->ensureStudentAccountLink($schoolId, $studentId, $childId);
                        $this->ensureParentLink($childId, $parents[$parentIndex]);
                        $this->ensureEnrollment($sectionId, $childId);
                        $studentRows[] = [
                            'child_id' => $childId,
                            'user_id' => $studentId,
                            'section_id' => $sectionId,
                            'student_number' => $studentIndex,
                        ];
                    }
                }

                $intakeChildId = $this->ensureChild((int) $organization->id, '[DEMO] طالب طلب التحاق تجريبي');
                $this->ensureParentLink($intakeChildId, $parents[1]);
                $this->ensurePendingEnrollmentRequest($intakeChildId, $schoolId, $parents[1]);

                $this->ensureTimetableSettings($schoolId);
                $this->ensureAssignmentsAndQuotas(
                    (int) $organization->id, $schoolId, $adminId,
                    $sectionIds, $subjectDefinitions, $subjectIds, $teacherIds
                );
                $this->ensureTimetable($schoolId, $yearId, $sectionIds, $subjectDefinitions, $subjectIds, $teacherIds);
                $this->ensureAttendance($schoolId, (int) $organization->id, $adminId, $sectionIds, $studentRows);
                $this->ensureStaffAttendance($schoolId, $adminId, array_values($teacherIds), $staffId);
                $this->ensureCurriculum($schoolId, $yearId, $gradeIds, $subjectDefinitions, $subjectIds, $adminId);

                return [
                    'year_id' => $yearId,
                    'grade_ids' => $gradeIds,
                    'subject_ids' => $subjectIds,
                    'section_ids' => $sectionIds,
                    'admin_id' => $adminId,
                    'director_id' => $directorId,
                    'teacher_ids' => $teacherIds,
                    'parent_ids' => $parents,
                    'student_count' => count($studentRows),
                ];
            }, 3);

            $this->newLine();
            $this->info('Jabalia synthetic fixture committed successfully.');
            $this->line('Academic year ID: '.$result['year_id']);
            $this->line('School ID: '.$schoolId);
            $this->line('Demo sections: '.implode(', ', $result['section_ids']));
            $this->line('Demo students enrolled: '.$result['student_count']);
            $this->line('Demo teacher accounts: '.count($result['teacher_ids']));
            $this->line('Demo parent accounts: '.count($result['parent_ids']));
            $this->line('Demo admin: demo.admin@example.test');
            $this->line('Demo director: demo.director@example.test');
            $this->line('Teacher logins: demo.teacher.ar@'.self::ORG_DOMAIN.', demo.teacher.math@'.self::ORG_DOMAIN.', demo.teacher.science@'.self::ORG_DOMAIN.', demo.teacher.social@'.self::ORG_DOMAIN.', demo.teacher.en@'.self::ORG_DOMAIN);
            $this->line('Student logins: demo.student.01@'.self::SCHOOL_DOMAIN.' through demo.student.08@'.self::SCHOOL_DOMAIN);
            $this->comment('All listed demo accounts use the one-time JABALIA_DEMO_PASSWORD supplied to this invocation.');
            $this->comment('No existing user, child, contract file, medical file or identity document was deleted.');
            $this->newLine();
            $this->table(['Fixture', 'Count'], $this->summaryRows($schoolId, $result['year_id']));
            return self::SUCCESS;
        } catch (\Throwable $exception) {
            $this->error('Jabalia demo fixture was not completed: '.$exception->getMessage());
            report($exception);
            return self::FAILURE;
        }
    }

    private function assertRequiredSchema(): void
    {
        $tables = [
            'organizations', 'organization_user', 'schools', 'users',
            'academic_years', 'academic_terms', 'grades', 'subjects', 'sections',
            'teacher_assignments', 'jabalia_teacher_profiles',
            'jabalia_teacher_assignment_history', 'jabalia_section_subject_quotas',
            'jabalia_school_timetable_settings', 'timetable_entries',
            'children', 'child_parent', 'student_enrollments', 'student_account_links',
            'school_internal_identities', 'institution_internal_identities',
            'institution_internal_account_events', 'school_management_assignments',
            'institution_director_profiles', 'institution_director_assignments',
            'school_enrollment_requests', 'attendance_sessions', 'attendance_records',
            'jabalia_attendance_change_events', 'school_staff_attendance',
            'curriculum_books', 'curriculum_units', 'curriculum_lessons',
            'noor_lesson_generations',
        ];
        $missing = array_values(array_filter($tables, fn ($table) => !Schema::hasTable($table)));
        if ($missing !== []) {
            throw new RuntimeException('Required migrations are missing: '.implode(', ', $missing));
        }
    }

    private function assertReservedDomains(object $organization, object $school): void
    {
        $orgDomain = $organization->internal_domain ?? null;
        if ($orgDomain !== null && $orgDomain !== self::ORG_DOMAIN) {
            throw new RuntimeException('Jabalia organization already has a different internal login domain; refusing to replace it.');
        }
        $schoolDomain = $school->internal_domain ?? null;
        if ($schoolDomain !== null && $schoolDomain !== self::SCHOOL_DOMAIN) {
            throw new RuntimeException('Jabalia school already has a different internal login domain; refusing to replace it.');
        }
        if (DB::table('organizations')->where('internal_domain', self::ORG_DOMAIN)
            ->where('id', '!=', $organization->id)->exists()) {
            throw new RuntimeException('The reserved demo organization login domain is already in use.');
        }
        if (DB::table('schools')->where('internal_domain', self::SCHOOL_DOMAIN)
            ->where('id', '!=', $school->id)->exists()) {
            throw new RuntimeException('The reserved demo school login domain is already in use.');
        }
    }

    private function assertNoConflictingDirector(object $school): void
    {
        $expectedEmail = 'demo.director@example.test';
        $expectedUser = DB::table('users')->where('email', $expectedEmail)->first();
        $active = DB::table('school_management_assignments')
            ->where('school_id', $school->id)->where('role', 'director')->whereNull('ends_at')->get();
        if ($active->count() > 1) {
            throw new RuntimeException('More than one active school director exists; refusing to modify appointments.');
        }
        if ($active->isNotEmpty() && (!$expectedUser || (int) $active->first()->user_id !== (int) $expectedUser->id)) {
            throw new RuntimeException('A different active director is appointed; review this before seeding the demo director.');
        }
    }

    private function archiveLegacyFixtures(int $schoolId): void
    {
        $years = DB::table('academic_years')->where('school_id', $schoolId)->get();
        $legacyYearIds = [];
        foreach ($years as $year) {
            if (!str_starts_with($year->name, 'DEMO-') && !str_starts_with($year->name, '[LEGACY TEST] ')) {
                $legacyYearIds[] = (int) $year->id;
                DB::table('academic_years')->where('id', $year->id)->update([
                    'name' => '[LEGACY TEST] '.$year->name,
                    'is_current' => false,
                    'updated_at' => now(),
                ]);
            }
        }
        foreach ($legacyYearIds as $yearId) {
            DB::table('academic_terms')->where('academic_year_id', $yearId)->get()->each(function ($term) {
                if (!str_starts_with($term->name, '[LEGACY TEST] ')) {
                    DB::table('academic_terms')->where('id', $term->id)->update([
                        'name' => '[LEGACY TEST] '.$term->name,
                        'updated_at' => now(),
                    ]);
                }
            });
        }

        $legacyGradeIds = [];
        foreach (DB::table('grades')->where('school_id', $schoolId)->get() as $grade) {
            if (!str_starts_with((string) $grade->code, 'DEMO-')
                && !str_starts_with($grade->name, '[LEGACY TEST] ')) {
                $legacyGradeIds[] = (int) $grade->id;
                DB::table('grades')->where('id', $grade->id)->update([
                    'name' => '[LEGACY TEST] '.$grade->name,
                    'code' => 'LEGACY-GRADE-'.$grade->id,
                    'is_active' => false,
                    'updated_at' => now(),
                ]);
            }
        }

        foreach (DB::table('subjects')->where('school_id', $schoolId)->get() as $subject) {
            if (!str_starts_with((string) $subject->code, 'DEMO-')
                && !str_starts_with($subject->name, '[LEGACY TEST] ')) {
                DB::table('subjects')->where('id', $subject->id)->update([
                    'name' => '[LEGACY TEST] '.$subject->name,
                    'code' => 'LEGACY-SUBJECT-'.$subject->id,
                    'is_active' => false,
                    'updated_at' => now(),
                ]);
            }
        }

        if ($legacyGradeIds !== [] || $legacyYearIds !== []) {
            $sections = DB::table('sections')->where(function ($query) use ($legacyGradeIds, $legacyYearIds) {
                if ($legacyGradeIds !== []) $query->whereIn('grade_id', $legacyGradeIds);
                if ($legacyYearIds !== []) {
                    $method = $legacyGradeIds === [] ? 'whereIn' : 'orWhereIn';
                    $query->{$method}('academic_year_id', $legacyYearIds);
                }
            })->get();
            foreach ($sections as $section) {
                if (!str_starts_with($section->name, '[LEGACY TEST] ')) {
                    DB::table('sections')->where('id', $section->id)->update([
                        'name' => '[LEGACY TEST] '.$section->name,
                        'updated_at' => now(),
                    ]);
                }
            }
        }
    }

    private function ensureAcademicYear(int $schoolId): int
    {
        $existing = DB::table('academic_years')->where('school_id', $schoolId)
            ->where('name', self::YEAR_NAME)->first();
        $values = [
            'starts_on' => '2026-09-01',
            'ends_on' => '2027-06-30',
            'is_current' => true,
            'updated_at' => now(),
        ];
        if ($existing) {
            DB::table('academic_years')->where('id', $existing->id)->update($values);
            return (int) $existing->id;
        }
        return (int) DB::table('academic_years')->insertGetId([
            'school_id' => $schoolId,
            'name' => self::YEAR_NAME,
            ...$values,
            'created_at' => now(),
        ]);
    }

    private function ensureTerms(int $yearId): void
    {
        $terms = [
            [1, '[DEMO] الفصل الأول', '2026-09-01', '2026-12-31'],
            [2, '[DEMO] الفصل الثاني', '2027-01-01', '2027-06-30'],
        ];
        foreach ($terms as [$position, $name, $start, $end]) {
            $existing = DB::table('academic_terms')->where('academic_year_id', $yearId)
                ->where('position', $position)->first();
            $values = [
                'name' => $name, 'starts_on' => $start, 'ends_on' => $end,
                'updated_at' => now(),
            ];
            if ($existing) DB::table('academic_terms')->where('id', $existing->id)->update($values);
            else DB::table('academic_terms')->insert([
                'academic_year_id' => $yearId, 'position' => $position,
                ...$values, 'created_at' => now(),
            ]);
        }
    }

    private function ensureGrade(int $schoolId, string $name, string $code, int $position): int
    {
        $existing = DB::table('grades')->where('school_id', $schoolId)->where('code', $code)->first();
        if (!$existing) {
            $idByName = DB::table('grades')->where('school_id', $schoolId)->where('name', $name)->first();
            $existing = $idByName;
        }
        $values = [
            'name' => $name, 'code' => $code, 'position' => $position,
            'is_active' => true, 'updated_at' => now(),
        ];
        if ($existing) {
            DB::table('grades')->where('id', $existing->id)->update($values);
            return (int) $existing->id;
        }
        return (int) DB::table('grades')->insertGetId([
            'school_id' => $schoolId, ...$values, 'created_at' => now(),
        ]);
    }

    private function ensureSubject(int $schoolId, string $name, string $code): int
    {
        $collision = DB::table('subjects')->where('school_id', $schoolId)
            ->whereRaw('UPPER(code) = ?', [strtoupper($code)])
            ->where('name', '!=', $name)->where('code', '!=', $code)->first();
        if ($collision) {
            throw new RuntimeException('A different subject already uses reserved demo code '.$code.'.');
        }
        $existing = DB::table('subjects')->where('school_id', $schoolId)->where('code', $code)->first();
        if (!$existing) $existing = DB::table('subjects')->where('school_id', $schoolId)->where('name', $name)->first();
        $values = ['name' => $name, 'code' => $code, 'is_active' => true, 'updated_at' => now()];
        if ($existing) {
            DB::table('subjects')->where('id', $existing->id)->update($values);
            return (int) $existing->id;
        }
        return (int) DB::table('subjects')->insertGetId([
            'school_id' => $schoolId, ...$values, 'created_at' => now(),
        ]);
    }

    private function ensureSection(int $gradeId, int $yearId, string $name): int
    {
        $existing = DB::table('sections')->where('grade_id', $gradeId)
            ->where('academic_year_id', $yearId)->where('name', $name)->first();
        $values = ['capacity' => 20, 'updated_at' => now()];
        if ($existing) {
            DB::table('sections')->where('id', $existing->id)->update($values);
            return (int) $existing->id;
        }
        return (int) DB::table('sections')->insertGetId([
            'grade_id' => $gradeId, 'academic_year_id' => $yearId,
            'name' => $name, ...$values, 'created_at' => now(),
        ]);
    }

    private function ensureUser(string $email, string $name, string $role, string $password): int
    {
        $existing = DB::table('users')->where('email', $email)->first();
        if ($existing && $existing->role !== $role) {
            throw new RuntimeException('Reserved demo email is already used by a different account role: '.$email);
        }
        $hash = Hash::make($password);
        $values = [
            'name' => $name,
            'email_verified_at' => now(),
            'password' => $hash,
            'updated_at' => now(),
        ];
        if (Schema::hasColumn('users', 'password_hash')) $values['password_hash'] = $hash;
        if (Schema::hasColumn('users', 'verification_status')) $values['verification_status'] = 'verified';
        if (!$existing) {
            $values['email'] = $email;
            $values['role'] = $role;
            $values['created_at'] = now();
            return (int) DB::table('users')->insertGetId($values);
        }
        DB::table('users')->where('id', $existing->id)->update($values);
        return (int) $existing->id;
    }

    private function ensureOrganizationMembership(int $organizationId, int $userId, string $role): void
    {
        $existing = DB::table('organization_user')->where('organization_id', $organizationId)
            ->where('user_id', $userId)->first();
        $values = ['role' => $role, 'is_active' => true, 'updated_at' => now()];
        if ($existing) DB::table('organization_user')->where('id', $existing->id)->update($values);
        else DB::table('organization_user')->insert([
            'organization_id' => $organizationId, 'user_id' => $userId,
            ...$values, 'created_at' => now(),
        ]);
    }

    private function ensureInstitutionTeacherIdentity(int $organizationId, int $teacherId, string $username, int $adminId): void
    {
        $byName = DB::table('institution_internal_identities')
            ->where('organization_id', $organizationId)->where('username', $username)->first();
        if ($byName && (int) $byName->user_id !== $teacherId) {
            throw new RuntimeException('Reserved demo teacher username is already bound to another user: '.$username);
        }
        $byUser = DB::table('institution_internal_identities')->where('user_id', $teacherId)->first();
        if ($byUser && ((int) $byUser->organization_id !== $organizationId || $byUser->username !== $username)) {
            throw new RuntimeException('Demo teacher already has a different internal identity: '.$username);
        }
        $values = [
            'organization_id' => $organizationId, 'user_id' => $teacherId,
            'username' => $username, 'is_active' => true,
            'must_change_password' => true, 'updated_at' => now(),
        ];
        if ($byUser) DB::table('institution_internal_identities')->where('id', $byUser->id)->update($values);
        else DB::table('institution_internal_identities')->insert([...$values, 'created_at' => now()]);
        $this->ensureInternalAccountEvent($organizationId, $adminId, $teacherId);
    }

    private function ensureInternalAccountEvent(int $organizationId, int $actorId, int $subjectId): void
    {
        $exists = DB::table('institution_internal_account_events')
            ->where('organization_id', $organizationId)->where('actor_id', $actorId)
            ->where('subject_id', $subjectId)->where('action', 'teacher_created')->exists();
        if (!$exists) DB::table('institution_internal_account_events')->insert([
            'organization_id' => $organizationId, 'actor_id' => $actorId,
            'subject_id' => $subjectId, 'action' => 'teacher_created', 'created_at' => now(),
        ]);
    }

    private function ensureSchoolIdentity(int $schoolId, int $userId, string $username): void
    {
        $byName = DB::table('school_internal_identities')
            ->where('school_id', $schoolId)->where('username', $username)->first();
        if ($byName && (int) $byName->user_id !== $userId) {
            throw new RuntimeException('Reserved demo school username is already bound to another user: '.$username);
        }
        $byUser = DB::table('school_internal_identities')->where('user_id', $userId)->first();
        if ($byUser && ((int) $byUser->school_id !== $schoolId || $byUser->username !== $username)) {
            throw new RuntimeException('Demo user already has a different school identity: '.$username);
        }
        $values = [
            'school_id' => $schoolId, 'user_id' => $userId,
            'username' => $username, 'is_active' => true, 'updated_at' => now(),
        ];
        if ($byUser) DB::table('school_internal_identities')->where('id', $byUser->id)->update($values);
        else DB::table('school_internal_identities')->insert([...$values, 'created_at' => now()]);
    }

    private function ensureDirector(int $schoolId, int $organizationId, int $adminId, int $directorId): void
    {
        $school = DB::table('schools')->where('id', $schoolId)->first();
        if ($school->internal_domain === null) {
            DB::table('schools')->where('id', $schoolId)->update([
                'internal_domain' => self::SCHOOL_DOMAIN,
                'internal_domain_confirmed_at' => now(),
                'updated_at' => now(),
            ]);
        } elseif ($school->internal_domain !== self::SCHOOL_DOMAIN) {
            throw new RuntimeException('School internal domain changed during fixture transaction.');
        } elseif ($school->internal_domain_confirmed_at === null) {
            DB::table('schools')->where('id', $schoolId)->update([
                'internal_domain_confirmed_at' => now(), 'updated_at' => now(),
            ]);
        }

        $organization = DB::table('organizations')->where('id', $organizationId)->first();
        if ($organization->internal_domain === null) {
            DB::table('organizations')->where('id', $organizationId)->update([
                'internal_domain' => self::ORG_DOMAIN, 'updated_at' => now(),
            ]);
        } elseif ($organization->internal_domain !== self::ORG_DOMAIN) {
            throw new RuntimeException('Organization internal domain changed during fixture transaction.');
        }

        $profile = DB::table('institution_director_profiles')->where('school_id', $schoolId)
            ->whereRaw('LOWER(email) = ?', ['demo.director@example.test'])->first();
        $profileValues = [
            'school_id' => $schoolId, 'name' => '[DEMO] مدير المدرسة',
            'email' => 'demo.director@example.test', 'phone' => '',
            'qualification' => '[DEMO] سجل إداري تجريبي',
            'experience_years' => 0, 'identity_user_id' => $directorId,
            'created_by' => $adminId, 'updated_by' => $adminId,
            'updated_at' => now(),
        ];
        if ($profile) {
            DB::table('institution_director_profiles')->where('id', $profile->id)->update($profileValues);
            $profileId = (int) $profile->id;
        } else {
            $profileId = (int) DB::table('institution_director_profiles')->insertGetId([
                ...$profileValues, 'created_at' => now(),
            ]);
        }

        $management = DB::table('school_management_assignments')->where('school_id', $schoolId)
            ->where('role', 'director')->whereNull('ends_at')->first();
        if ($management && (int) $management->user_id !== $directorId) {
            throw new RuntimeException('A different active director appointment exists.');
        }
        if (!$management) {
            DB::table('school_management_assignments')->insert([
                'school_id' => $schoolId, 'user_id' => $directorId, 'role' => 'director',
                'appointed_by' => $adminId, 'starts_at' => now(), 'ends_at' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }

        $directory = DB::table('institution_director_assignments')->where('school_id', $schoolId)
            ->whereNull('ended_on')->first();
        if ($directory && (int) $directory->director_id !== $profileId) {
            throw new RuntimeException('A different active directory director profile exists.');
        }
        if (!$directory) {
            DB::table('institution_director_assignments')->insert([
                'school_id' => $schoolId, 'director_id' => $profileId,
                'starts_on' => self::FIXTURE_DATE, 'ended_on' => null,
                'appointed_by' => $adminId, 'ended_by' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }

        $event = DB::table('school_administration_events')->where('school_id', $schoolId)
            ->where('actor_id', $adminId)->where('subject_id', $directorId)
            ->where('action', 'demo_director_seeded')->exists();
        if (!$event) DB::table('school_administration_events')->insert([
            'school_id' => $schoolId, 'actor_id' => $adminId,
            'action' => 'demo_director_seeded', 'subject_id' => $directorId,
            'created_at' => now(),
        ]);
    }

    private function ensureTeacherProfile(int $organizationId, int $teacherId, string $subjectCode): void
    {
        $existing = DB::table('jabalia_teacher_profiles')
            ->where('organization_id', $organizationId)->where('teacher_id', $teacherId)->first();
        $values = [
            'qualification' => '[DEMO] مؤهل تجريبي',
            'specialization' => '[DEMO] '.$subjectCode,
            'experience_years' => 1,
            'professional_notes' => '[DEMO] Synthetic profile. Not an HR record.',
            'updated_at' => now(),
        ];
        if ($existing) DB::table('jabalia_teacher_profiles')->where('id', $existing->id)->update($values);
        else DB::table('jabalia_teacher_profiles')->insert([
            'organization_id' => $organizationId, 'teacher_id' => $teacherId,
            ...$values, 'created_at' => now(),
        ]);
    }

    private function teacherDisplayName(string $code): string
    {
        return match ($code) {
            'DEMO-AR' => 'معلم اللغة العربية',
            'DEMO-MA' => 'معلم الرياضيات',
            'DEMO-SC' => 'معلم العلوم',
            'DEMO-SS' => 'معلم الدراسات الاجتماعية',
            'DEMO-EN' => 'معلم اللغة الإنجليزية',
            default => 'معلم تجريبي',
        };
    }

    private function ensureChild(int $organizationId, string $name): int
    {
        $existing = DB::table('children')->where('organization_id', $organizationId)->where('name', $name)->first();
        $values = ['status' => 'active'];
        if (Schema::hasColumn('children', 'updated_at')) $values['updated_at'] = now();
        if ($existing) {
            DB::table('children')->where('id', $existing->id)->update($values);
            return (int) $existing->id;
        }
        $values['name'] = $name;
        $values['organization_id'] = $organizationId;
        $values['created_at'] = now();
        return (int) DB::table('children')->insertGetId($values);
    }

    private function ensureParentLink(int $childId, int $parentId): void
    {
        DB::table('child_parent')->insertOrIgnore([
            'child_id' => $childId, 'parent_id' => $parentId,
        ]);
    }

    private function ensureStudentAccountLink(int $schoolId, int $userId, int $childId): void
    {
        $existing = DB::table('student_account_links')->where('child_id', $childId)->first();
        if ($existing && (int) $existing->user_id !== $userId) {
            throw new RuntimeException('A demo student child is already linked to a different user.');
        }
        $values = [
            'user_id' => $userId, 'child_id' => $childId,
            'school_id' => $schoolId, 'updated_at' => now(),
        ];
        if ($existing) DB::table('student_account_links')->where('id', $existing->id)->update($values);
        else DB::table('student_account_links')->insert([...$values, 'created_at' => now()]);
    }

    private function ensureEnrollment(int $sectionId, int $childId): void
    {
        $existing = DB::table('student_enrollments')->where('section_id', $sectionId)
            ->where('child_id', $childId)->first();
        $values = [
            'status' => 'active', 'enrolled_on' => self::FIXTURE_DATE,
            'left_on' => null, 'updated_at' => now(),
        ];
        if ($existing) DB::table('student_enrollments')->where('id', $existing->id)->update($values);
        else DB::table('student_enrollments')->insert([
            'section_id' => $sectionId, 'child_id' => $childId,
            ...$values, 'created_at' => now(),
        ]);
    }

    private function ensurePendingEnrollmentRequest(int $childId, int $schoolId, int $parentId): void
    {
        $existing = DB::table('school_enrollment_requests')->where('child_id', $childId)
            ->where('school_id', $schoolId)->where('status', 'pending')->first();
        if ($existing) return;
        DB::table('school_enrollment_requests')->insert([
            'child_id' => $childId, 'school_id' => $schoolId,
            'requested_by' => $parentId, 'status' => 'pending', 'version' => 1,
            'reason' => '[DEMO] Synthetic intake request for acceptance testing.',
            'decided_by' => null, 'decided_at' => null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    private function ensureTimetableSettings(int $schoolId): void
    {
        $settings = \App\Http\Controllers\JabaliaTimetableSettingsController::defaults();
        DB::table('jabalia_school_timetable_settings')->updateOrInsert(
            ['school_id' => $schoolId],
            [
                'weekdays' => json_encode($settings['weekdays']),
                'periods' => json_encode($settings['periods']),
                'updated_at' => now(),
            ]
        );
    }

    private function ensureAssignmentsAndQuotas(
        int $organizationId,
        int $schoolId,
        int $adminId,
        array $sectionIds,
        array $subjectDefinitions,
        array $subjectIds,
        array $teacherIds
    ): void {
        foreach ($sectionIds as $sectionId) {
            foreach ($subjectDefinitions as $definition) {
                $subjectId = $subjectIds[$definition['code']];
                $teacherId = $teacherIds[$definition['code']];
                $active = DB::table('teacher_assignments')->where('section_id', $sectionId)
                    ->where('subject_id', $subjectId)->where('status', 'active')->first();
                if ($active && (int) $active->teacher_id !== $teacherId) {
                    throw new RuntimeException('A different active teacher is already assigned to a demo section/subject.');
                }
                if (!$active) {
                    DB::table('teacher_assignments')->insert([
                        'section_id' => $sectionId, 'subject_id' => $subjectId,
                        'teacher_id' => $teacherId, 'status' => 'active',
                        'starts_on' => self::FIXTURE_DATE, 'ends_on' => null,
                        'created_at' => now(), 'updated_at' => now(),
                    ]);
                }

                $history = DB::table('jabalia_teacher_assignment_history')
                    ->where('organization_id', $organizationId)->where('school_id', $schoolId)
                    ->where('teacher_id', $teacherId)->where('section_id', $sectionId)
                    ->where('subject_id', $subjectId)->where('status', 'active')->first();
                if (!$history) DB::table('jabalia_teacher_assignment_history')->insert([
                    'organization_id' => $organizationId, 'school_id' => $schoolId,
                    'teacher_id' => $teacherId, 'section_id' => $sectionId,
                    'subject_id' => $subjectId, 'starts_on' => self::FIXTURE_DATE,
                    'ends_on' => null, 'status' => 'active',
                    'reason' => '[DEMO] Synthetic teaching assignment.',
                    'recorded_by' => $adminId, 'created_at' => now(), 'updated_at' => now(),
                ]);

                $quota = DB::table('jabalia_section_subject_quotas')->where('section_id', $sectionId)
                    ->where('subject_id', $subjectId)->first();
                $quotaValues = [
                    'school_id' => $schoolId,
                    'weekly_periods' => $definition['quota'],
                    'updated_at' => now(),
                ];
                if ($quota) DB::table('jabalia_section_subject_quotas')->where('id', $quota->id)->update($quotaValues);
                else DB::table('jabalia_section_subject_quotas')->insert([
                    'section_id' => $sectionId, 'subject_id' => $subjectId,
                    ...$quotaValues, 'created_at' => now(),
                ]);
            }
        }
    }

    private function ensureTimetable(
        int $schoolId,
        int $yearId,
        array $sectionIds,
        array $subjectDefinitions,
        array $subjectIds,
        array $teacherIds
    ): void {
        $settings = \App\Http\Controllers\JabaliaTimetableSettingsController::forSchool($schoolId);
        $slots = [];
        foreach ($settings['weekdays'] as $weekday) {
            foreach ($settings['periods'] as $index => $period) {
                $slots[] = [
                    'weekday' => (int) $weekday,
                    'period_number' => $index + 1,
                    'starts_at' => $period['starts_at'],
                    'ends_at' => $period['ends_at'],
                ];
            }
        }

        $sectionUsed = [];
        $teacherUsed = [];
        foreach ($sectionIds as $sectionId) {
            foreach ($subjectDefinitions as $definition) {
                $subjectCode = $definition['code'];
                $teacherId = $teacherIds[$subjectCode];
                for ($lesson = 0; $lesson < $definition['quota']; $lesson++) {
                    $chosen = null;
                    foreach ($slots as $slot) {
                        $key = $slot['weekday'].':'.$slot['period_number'];
                        if (isset($sectionUsed[$sectionId][$key]) || isset($teacherUsed[$teacherId][$key])) continue;
                        $chosen = $slot;
                        $sectionUsed[$sectionId][$key] = true;
                        $teacherUsed[$teacherId][$key] = true;
                        break;
                    }
                    if ($chosen === null) {
                        throw new RuntimeException('Could not allocate a conflict-free demo timetable within the configured week.');
                    }

                    $existing = DB::table('timetable_entries')->where('school_id', $schoolId)
                        ->where('section_id', $sectionId)->where('weekday', $chosen['weekday'])
                        ->where('period_number', $chosen['period_number'])->first();
                    $values = [
                        'school_id' => $schoolId, 'academic_year_id' => $yearId,
                        'section_id' => $sectionId, 'subject_id' => $subjectIds[$subjectCode],
                        'teacher_id' => $teacherId, 'weekday' => $chosen['weekday'],
                        'period_number' => $chosen['period_number'],
                        'starts_at' => $chosen['starts_at'], 'ends_at' => $chosen['ends_at'],
                        'room' => 'DEMO-R'.$sectionId, 'updated_at' => now(),
                    ];
                    if ($existing) {
                        if ((int) $existing->academic_year_id !== $yearId
                            || (int) $existing->subject_id !== $values['subject_id']
                            || (int) $existing->teacher_id !== $teacherId) {
                            throw new RuntimeException('A demo timetable slot is already occupied by a different entry.');
                        }
                        DB::table('timetable_entries')->where('id', $existing->id)->update($values);
                    } else {
                        DB::table('timetable_entries')->insert([...$values, 'created_at' => now()]);
                    }
                }
            }
        }
    }

    private function ensureAttendance(
        int $schoolId,
        int $organizationId,
        int $adminId,
        array $sectionIds,
        array $studentRows
    ): void {
        $today = self::FIXTURE_DATE;
        foreach ($sectionIds as $sectionId) {
            $session = DB::table('attendance_sessions')->where('section_id', $sectionId)
                ->whereDate('attendance_date', $today)->whereNull('period_number')->first();
            if ($session && !str_starts_with((string) $session->notes, '[DEMO]')) {
                throw new RuntimeException('A non-demo daily attendance session already exists on the reserved demo fixture date.');
            }
            if (!$session) {
                $sessionId = (int) DB::table('attendance_sessions')->insertGetId([
                    'section_id' => $sectionId, 'subject_id' => null, 'teacher_id' => null,
                    'attendance_date' => $today, 'period_number' => null,
                    'status' => 'open', 'notes' => '[DEMO] Synthetic daily attendance roll.',
                    'created_at' => now(), 'updated_at' => now(),
                ]);
            } else {
                $sessionId = (int) $session->id;
            }

            foreach ($studentRows as $student) {
                if ((int) $student['section_id'] !== $sectionId) continue;
                $status = ((int) $student['student_number'] === 8) ? 'late' : 'present';
                $record = DB::table('attendance_records')->where('attendance_session_id', $sessionId)
                    ->where('child_id', $student['child_id'])->first();
                $values = [
                    'status' => $status, 'note' => '[DEMO] Synthetic attendance record.',
                    'marked_by' => $adminId, 'marked_at' => now(), 'updated_at' => now(),
                ];
                if ($record) DB::table('attendance_records')->where('id', $record->id)->update($values);
                else DB::table('attendance_records')->insert([
                    'attendance_session_id' => $sessionId, 'child_id' => $student['child_id'],
                    ...$values, 'created_at' => now(),
                ]);

                $event = DB::table('jabalia_attendance_change_events')
                    ->where('organization_id', $organizationId)->where('school_id', $schoolId)
                    ->where('attendance_session_id', $sessionId)->where('child_id', $student['child_id'])
                    ->whereNull('previous_status')->where('new_status', $status)->exists();
                if (!$event) DB::table('jabalia_attendance_change_events')->insert([
                    'organization_id' => $organizationId, 'school_id' => $schoolId,
                    'attendance_session_id' => $sessionId, 'child_id' => $student['child_id'],
                    'previous_status' => null, 'new_status' => $status,
                    'actor_id' => $adminId, 'created_at' => now(),
                ]);
            }
        }
    }

    private function ensureStaffAttendance(int $schoolId, int $adminId, array $teacherIds, int $staffId): void
    {
        foreach ([...$teacherIds, $staffId] as $userId) {
            $existing = DB::table('school_staff_attendance')->where('school_id', $schoolId)
                ->where('user_id', $userId)->whereDate('attendance_date', self::FIXTURE_DATE)->first();
            $values = ['status' => 'present', 'recorded_by' => $adminId, 'updated_at' => now()];
            if ($existing) DB::table('school_staff_attendance')->where('id', $existing->id)->update($values);
            else DB::table('school_staff_attendance')->insert([
                'school_id' => $schoolId, 'user_id' => $userId,
                'attendance_date' => self::FIXTURE_DATE,
                ...$values, 'created_at' => now(),
            ]);
        }
    }

    private function ensureCurriculum(
        int $schoolId,
        int $yearId,
        array $gradeIds,
        array $subjectDefinitions,
        array $subjectIds,
        int $adminId
    ): void {
        $lessonContents = [
            'DEMO-AR' => 'يتدرب المتعلم على قراءة جملة قصيرة، وتحديد الفكرة الرئيسة، وترتيب الكلمات لتكوين معنى واضح. هذا نص أصلي أُعد للاختبار فقط.',
            'DEMO-MA' => 'يتعرف المتعلم إلى القيمة المكانية للأرقام، ويمثل العدد باستخدام بطاقات الآحاد والعشرات والمئات، ثم يقارن بين عددين.',
            'DEMO-SC' => 'يلاحظ المتعلم أشياء من البيئة الصفية، ويصنفها وفق خاصية واحدة واضحة، ثم يشرح سبب اختياره.',
            'DEMO-SS' => 'يتعرف المتعلم إلى مرافق المجتمع المحلي وأدوارها، ويربط كل مرفق بخدمة يقدمها للناس.',
            'DEMO-EN' => 'Learners practise a small set of everyday words, match each word to an original classroom illustration, and use it in a short sentence.',
        ];
        $firstLessonId = null;
        foreach ($gradeIds as $gradeIndex => $gradeId) {
            foreach ($subjectDefinitions as $definition) {
                $code = $definition['code'];
                $title = '[DEMO] '.$definition['lesson'].' - Grade '.($gradeIndex + 1);
                $book = DB::table('curriculum_books')->where('school_id', $schoolId)
                    ->where('academic_year_id', $yearId)->where('grade_id', $gradeId)
                    ->where('subject_id', $subjectIds[$code])->where('title', $title)->first();
                if (!$book) {
                    $bookId = (int) DB::table('curriculum_books')->insertGetId([
                        'school_id' => $schoolId, 'academic_year_id' => $yearId,
                        'grade_id' => $gradeId, 'subject_id' => $subjectIds[$code],
                        'title' => $title, 'semester' => 'DEMO-TERM-1',
                        'edition' => 'Synthetic original content v1',
                        'source_name' => 'EduBridge original demo material',
                        'source_url' => null, 'storage_path' => null,
                        'status' => 'draft', 'created_at' => now(), 'updated_at' => now(),
                    ]);
                } else {
                    $bookId = (int) $book->id;
                }

                $unit = DB::table('curriculum_units')->where('curriculum_book_id', $bookId)
                    ->where('position', 1)->first();
                if (!$unit) {
                    $unitId = (int) DB::table('curriculum_units')->insertGetId([
                        'curriculum_book_id' => $bookId, 'title' => '[DEMO] الوحدة الأولى',
                        'position' => 1, 'created_at' => now(), 'updated_at' => now(),
                    ]);
                } else {
                    $unitId = (int) $unit->id;
                }

                $lesson = DB::table('curriculum_lessons')->where('curriculum_unit_id', $unitId)
                    ->where('position', 1)->first();
                if (!$lesson) {
                    $lessonId = (int) DB::table('curriculum_lessons')->insertGetId([
                        'curriculum_unit_id' => $unitId,
                        'title' => '[DEMO] '.$definition['lesson'],
                        'position' => 1, 'source_pages' => null,
                        'content_text' => $lessonContents[$code],
                        'metadata' => json_encode(['fixture' => 'jabalia-demo', 'original' => true]),
                        'created_at' => now(), 'updated_at' => now(),
                    ]);
                } else {
                    $lessonId = (int) $lesson->id;
                }
                $firstLessonId ??= $lessonId;
            }
        }

        if ($firstLessonId !== null) {
            $existing = DB::table('noor_lesson_generations')->where('school_id', $schoolId)
                ->where('curriculum_lesson_id', $firstLessonId)
                ->where('generation_type', 'visual_lesson_plan')->first();
            if (!$existing) {
                $output = [
                    'objectives' => ['تحديد الفكرة الرئيسة في النص القصير', 'ترتيب ثلاث كلمات في جملة مفهومة'],
                    'simplified_explanation' => 'اقرأ الجملة، وحدد الكلمة المهمة، ثم أعد ترتيب الكلمات لتكوين معنى واضح.',
                    'key_concepts' => ['قراءة', 'فكرة رئيسة', 'ترتيب الكلمات'],
                    'visual_sequence' => ['بطاقة كلمة', 'بطاقة صورة أصلية', 'ترتيب البطاقات', 'مراجعة الجملة'],
                    'sign_keywords' => ['قراءة', 'فكرة', 'ترتيب'],
                    'classroom_activity' => 'يرتب الطلاب بطاقات كلمات أصلية في مجموعات صغيرة.',
                    'assessment_questions' => ['ما الفكرة الرئيسة؟', 'أي كلمة تأتي أولاً؟'],
                    'worksheet_items' => ['رتب ثلاث كلمات لتكوين جملة.', 'اختر عنواناً مناسباً للجملة.'],
                    'parent_summary' => 'تدرب الطالب على فهم جملة قصيرة وترتيب كلماتها.',
                    'source_note' => 'مسودة تعليمية أصلية تجريبية. الكلمات ليست وصفاً لإشارات لغة الإشارة، وتحتاج مراجعة المعلم.',
                ];
                DB::table('noor_lesson_generations')->insert([
                    'school_id' => $schoolId, 'curriculum_lesson_id' => $firstLessonId,
                    'requested_by' => $adminId, 'generation_type' => 'visual_lesson_plan',
                    'output' => json_encode($output, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                    'status' => 'draft', 'approved_by' => null, 'approved_at' => null,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
            }
        }
    }

    private function summaryRows(int $schoolId, int $yearId): array
    {
        $sections = DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('g.school_id', $schoolId)->where('s.academic_year_id', $yearId)->count();
        $assignments = DB::table('teacher_assignments as a')->join('sections as s', 's.id', '=', 'a.section_id')
            ->whereIn('s.id', DB::table('sections')->where('academic_year_id', $yearId)->select('id'))
            ->where('a.status', 'active')->count();
        return [
            ['Demo sections', (string) $sections],
            ['Active teacher assignments', (string) $assignments],
            ['Subject quotas', (string) DB::table('jabalia_section_subject_quotas')->where('school_id', $schoolId)->whereIn('section_id', DB::table('sections')->where('academic_year_id', $yearId)->select('id'))->count()],
            ['Timetable entries', (string) DB::table('timetable_entries')->where('school_id', $schoolId)->where('academic_year_id', $yearId)->count()],
            ['Student enrollments', (string) DB::table('student_enrollments')->whereIn('section_id', DB::table('sections')->where('academic_year_id', $yearId)->select('id'))->where('status', 'active')->count()],
            ['Demo attendance sessions', (string) DB::table('attendance_sessions')->whereIn('section_id', DB::table('sections')->where('academic_year_id', $yearId)->select('id'))->whereDate('attendance_date', self::FIXTURE_DATE)->whereNull('period_number')->count()],
            ['Curriculum books', (string) DB::table('curriculum_books')->where('school_id', $schoolId)->where('academic_year_id', $yearId)->count()],
        ];
    }
}
