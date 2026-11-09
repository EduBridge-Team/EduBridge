<?php
/**
 * Populate a disposable GitHub Actions PostgreSQL database with synthetic
 * teacher/admission binary references. Never used by production entrypoints.
 */
declare(strict_types=1);

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

require __DIR__.'/../edubridge-api-laravel/vendor/autoload.php';
$app = require __DIR__.'/../edubridge-api-laravel/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

if (getenv('GITHUB_ACTIONS') !== 'true'
    || getenv('JABALIA_RECOVERY_SYNTHETIC') !== '1'
    || getenv('APP_ENV') !== 'testing'
    || getenv('DB_CONNECTION') !== 'pgsql'
    || getenv('DB_HOST') !== '127.0.0.1'
    || getenv('DB_DATABASE') !== 'jabalia_recovery_source_ci') {
    fwrite(STDERR, "REFUSED: this fixture requires the exact disposable CI source database\n");
    exit(2);
}

if (DB::table('users')->exists() || DB::table('organizations')->exists()
    || DB::table('jabalia_teacher_documents')->exists()
    || DB::table('jabalia_admission_documents')->exists()) {
    fwrite(STDERR, "REFUSED: database must contain no identity or private document records\n");
    exit(2);
}

$password = password_hash('SyntheticRecoveryPass!2026', PASSWORD_BCRYPT);
$users = [
    ['id' => 8101, 'name' => 'Synthetic Jabalia Owner', 'email' => 'ci-recovery-owner@example.test', 'role' => 'institution'],
    ['id' => 8102, 'name' => 'Synthetic Foreign Owner', 'email' => 'ci-recovery-foreign@example.test', 'role' => 'institution'],
    ['id' => 8103, 'name' => 'Synthetic Teacher', 'email' => 'ci-recovery-teacher@example.test', 'role' => 'teacher'],
    ['id' => 8104, 'name' => 'Synthetic Guardian', 'email' => 'ci-recovery-parent@example.test', 'role' => 'parent'],
    ['id' => 8105, 'name' => 'Synthetic Other Guardian', 'email' => 'ci-recovery-other-parent@example.test', 'role' => 'parent'],
    ['id' => 8106, 'name' => 'Synthetic Director', 'email' => 'ci-recovery-director@example.test', 'role' => 'school_director'],
];

DB::transaction(function () use ($users, $password): void {
    foreach ($users as $user) {
        DB::table('users')->insert(array_merge($user, [
            'password' => $password,
            'password_hash' => $password,
            'email_verified_at' => now(),
            'verification_status' => 'verified',
            'session_version' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]));
    }

    DB::table('organizations')->insert([
        ['id' => 8201, 'name' => 'Synthetic Jabalia CI Organization', 'slug' => 'jabalia',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['id' => 8202, 'name' => 'Synthetic Foreign CI Organization', 'slug' => 'foreign-recovery',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('organization_user')->insert([
        ['organization_id' => 8201, 'user_id' => 8101, 'role' => 'owner',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['organization_id' => 8201, 'user_id' => 8103, 'role' => 'teacher',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['organization_id' => 8202, 'user_id' => 8102, 'role' => 'owner',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('schools')->insert([
        ['id' => 8301, 'organization_id' => 8201, 'name' => 'Synthetic Jabalia School A',
            'slug' => 'jabalia-ci-a', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['id' => 8302, 'organization_id' => 8201, 'name' => 'Synthetic Jabalia School B',
            'slug' => 'jabalia-ci-b', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['id' => 8303, 'organization_id' => 8202, 'name' => 'Synthetic Foreign School',
            'slug' => 'foreign-ci', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('school_management_assignments')->insert([
        'school_id' => 8301, 'user_id' => 8106, 'role' => 'director',
        'appointed_by' => 8101, 'starts_at' => now()->subDays(3), 'ends_at' => null,
        'created_at' => now(), 'updated_at' => now(),
    ]);
    DB::table('children')->insert([
        ['id' => 8401, 'name' => 'Synthetic Child A', 'organization_id' => 8201],
        ['id' => 8402, 'name' => 'Synthetic Child B', 'organization_id' => 8202],
    ]);
    DB::table('child_parent')->insert([
        ['child_id' => 8401, 'parent_id' => 8104],
        ['child_id' => 8402, 'parent_id' => 8105],
    ]);
    DB::table('school_enrollment_requests')->insert([
        ['id' => 8501, 'child_id' => 8401, 'school_id' => 8301,
            'requested_by' => 8104, 'status' => 'pending', 'version' => 1,
            'created_at' => now(), 'updated_at' => now()],
        ['id' => 8502, 'child_id' => 8402, 'school_id' => 8303,
            'requested_by' => 8105, 'status' => 'pending', 'version' => 1,
            'created_at' => now(), 'updated_at' => now()],
    ]);

    $teacherBytes = "%PDF-1.4\nSYNTHETIC-JABALIA-TEACHER-RECOVERY-ONLY\n%%EOF\n";
    $admissionBytes = "%PDF-1.4\nSYNTHETIC-JABALIA-ADMISSION-RECOVERY-ONLY\n%%EOF\n";
    DB::table('jabalia_teacher_documents')->insert([
        'id' => 8601, 'organization_id' => 8201, 'school_id' => 8301,
        'teacher_id' => 8103, 'type' => 'certificate', 'title' => 'Synthetic personnel certificate',
        'recorded_by' => 8101, 'storage_path' => 'jabalia-teacher-documents/recovery-ci-teacher.pdf',
        'original_filename' => 'recovery-ci-teacher.pdf', 'mime_type' => 'application/pdf',
        'file_size' => strlen($teacherBytes), 'created_at' => now(), 'updated_at' => now(),
    ]);
    DB::table('jabalia_admission_documents')->insert([
        'id' => 8701, 'enrollment_request_id' => 8501, 'school_id' => 8301,
        'child_id' => 8401, 'type' => 'birth_certificate',
        'storage_path' => 'jabalia-admission-documents/recovery-ci-admission.pdf',
        'mime_type' => 'application/pdf', 'file_size' => strlen($admissionBytes),
        'uploaded_by' => 8104, 'created_at' => now(), 'updated_at' => now(),
    ]);
});

$disk = Storage::disk('local');
if (!$disk->put('jabalia-teacher-documents/recovery-ci-teacher.pdf',
    "%PDF-1.4\nSYNTHETIC-JABALIA-TEACHER-RECOVERY-ONLY\n%%EOF\n")
    || !$disk->put('jabalia-admission-documents/recovery-ci-admission.pdf',
    "%PDF-1.4\nSYNTHETIC-JABALIA-ADMISSION-RECOVERY-ONLY\n%%EOF\n")) {
    fwrite(STDERR, "ERROR: synthetic private test files could not be created\n");
    exit(3);
}

echo "PASS: disposable synthetic Jabalia database and two private files seeded\n";
