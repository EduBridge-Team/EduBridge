<?php
/**
 * Synthetic fixture for the disposable PostgreSQL GitHub Actions service only.
 * Never run against Oracle or another persistent database.
 */
declare(strict_types=1);

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;

require __DIR__.'/../edubridge-api-laravel/vendor/autoload.php';
$app = require __DIR__.'/../edubridge-api-laravel/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

if (getenv('APP_ENV') !== 'testing'
    || getenv('DB_HOST') !== '127.0.0.1'
    || getenv('DIRECTOR_STAGING_SYNTHETIC') !== '1'
    || getenv('DB_DATABASE') !== 'edubridge_director_ci') {
    fwrite(STDERR, "REFUSED: staging fixture requires disposable CI database\n");
    exit(2);
}

DB::transaction(function (): void {
    if (DB::table('users')->exists() || DB::table('organizations')->exists()) {
        throw new RuntimeException('REFUSED: staging database is not empty');
    }
    $password = password_hash('SyntheticDirectorStagingPass!2026', PASSWORD_BCRYPT);
    foreach ([
        ['id' => 8101, 'name' => 'Synthetic Operator', 'email' => 'synthetic-owner@example.test', 'role' => 'institution'],
        ['id' => 8102, 'name' => 'Synthetic Other Operator', 'email' => 'synthetic-foreign@example.test', 'role' => 'institution'],
        ['id' => 8103, 'name' => 'Synthetic Director A', 'email' => 'synthetic-a@example.test', 'role' => 'school_director'],
        ['id' => 8104, 'name' => 'Synthetic Director B', 'email' => 'synthetic-b@example.test', 'role' => 'school_director'],
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
        ['id' => 8201, 'name' => 'Synthetic Institution', 'slug' => 'director-staging', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now()],
        ['id' => 8202, 'name' => 'Other Synthetic Institution', 'slug' => 'foreign-staging', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('organization_user')->insert([
        ['organization_id' => 8201, 'user_id' => 8101, 'role' => 'owner',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['organization_id' => 8202, 'user_id' => 8102, 'role' => 'owner',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('schools')->insert([
        ['id' => 8301, 'organization_id' => 8201, 'name' => 'Synthetic School A',
            'slug' => 'synthetic-school-a', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['id' => 8302, 'organization_id' => 8201, 'name' => 'Synthetic School B',
            'slug' => 'synthetic-school-b', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ['id' => 8303, 'organization_id' => 8202, 'name' => 'Foreign School',
            'slug' => 'foreign-school', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('institution_director_profiles')->insert([
        ['id' => 8401, 'school_id' => 8301, 'name' => 'Synthetic Director A',
            'email' => 'synthetic-a@example.test', 'identity_user_id' => 8103,
            'experience_years' => 3, 'created_at' => now(), 'updated_at' => now()],
        ['id' => 8402, 'school_id' => 8301, 'name' => 'Synthetic Director B',
            'email' => 'synthetic-b@example.test', 'identity_user_id' => 8104,
            'experience_years' => 5, 'created_at' => now(), 'updated_at' => now()],
    ]);
    DB::table('school_management_assignments')->insert([
        'school_id' => 8301, 'user_id' => 8103, 'role' => 'director', 'appointed_by' => 8101,
        'starts_at' => now()->subDays(3), 'ends_at' => null, 'created_at' => now(), 'updated_at' => now(),
    ]);
    DB::table('institution_director_assignments')->insert([
        'school_id' => 8301, 'director_id' => 8401,
        'starts_on' => now()->subDays(3)->toDateString(), 'ended_on' => null,
        'appointed_by' => 8101, 'ended_by' => null,
        'created_at' => now(), 'updated_at' => now(),
    ]);
});
echo "PASS: synthetic, disposable director fixture created; no sensitive values emitted\n";
