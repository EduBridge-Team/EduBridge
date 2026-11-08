<?php
/**
 * Synthetic A12 identities for the disposable academic PostgreSQL CI service.
 * Must never run on Oracle, Jabalia, production, or a persistent database.
 */
declare(strict_types=1);

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;

require __DIR__.'/../edubridge-api-laravel/vendor/autoload.php';
$app = require __DIR__.'/../edubridge-api-laravel/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

if (getenv('APP_ENV') !== 'testing'
    || getenv('DB_CONNECTION') !== 'pgsql'
    || getenv('DB_HOST') !== '127.0.0.1'
    || getenv('DB_PORT') !== '5432'
    || getenv('DB_DATABASE') !== 'edubridge_academic_ci'
    || getenv('ACADEMIC_STAGING_SYNTHETIC') !== '1') {
    fwrite(STDERR, "REFUSED: A12 fixture only accepts disposable PostgreSQL CI\n");
    exit(2);
}

DB::transaction(function (): void {
    if (DB::table('users')->exists()
        || DB::table('organizations')->exists()
        || DB::table('schools')->exists()
        || DB::table('academic_years')->exists()) {
        throw new RuntimeException('REFUSED: A12 CI database is not empty');
    }

    $password = password_hash('SyntheticAcademicStagingPass!2026', PASSWORD_BCRYPT);
    foreach ([
        ['id' => 9101, 'name' => 'Synthetic School A', 'email' => 'synthetic-academic-a@example.test', 'role' => 'school'],
        ['id' => 9102, 'name' => 'Synthetic School B', 'email' => 'synthetic-academic-b@example.test', 'role' => 'school'],
        ['id' => 9103, 'name' => 'Synthetic Unauthorized User', 'email' => 'synthetic-academic-outsider@example.test', 'role' => 'teacher'],
    ] as $user) {
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
        'id' => 9201, 'name' => 'Synthetic Academic Institution',
        'slug' => 'academic-ci', 'is_active' => true,
        'created_at' => now(), 'updated_at' => now(),
    ]);
    DB::table('schools')->insert([
        ['id' => 9301, 'organization_id' => 9201, 'name' => 'Synthetic Academic Affiliated School',
            'slug' => 'synthetic-academic-affiliated', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now()],
        ['id' => 9302, 'organization_id' => null, 'name' => 'Synthetic Academic Independent School',
            'slug' => 'synthetic-academic-independent', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('school_accounts')->insert([
        ['school_id' => 9301, 'user_id' => 9101, 'created_at' => now(), 'updated_at' => now()],
        ['school_id' => 9302, 'user_id' => 9102, 'created_at' => now(), 'updated_at' => now()],
    ]);
});
echo "PASS: A12 synthetic school identities seeded into disposable PostgreSQL only\n";
