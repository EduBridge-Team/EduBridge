<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class FreshPostgresMigrationTest extends TestCase
{
    public function test_fresh_database_contains_core_edubridge_tables(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            $this->markTestSkipped('Fresh schema smoke test requires PostgreSQL.');
        }

        Artisan::call('migrate:fresh', ['--force' => true]);

        foreach ([
            'users',
            'children',
            'lessons',
            'sessions',
            'learning_support_requests',
            'homeworks',
            'weekly_reports',
            'case_discussions',
            'conversations',
            'user_settings',
            'child_accessibility_profiles',
        ] as $table) {
            $this->assertTrue(Schema::hasTable($table), "Missing table: {$table}");
        }

        $this->assertTrue(Schema::hasColumn('users', 'role'));
        $this->assertTrue(Schema::hasColumn('users', 'password_hash'));
        $this->assertTrue(Schema::hasColumn('sessions', 'learning_support_request_id'));
        $this->assertTrue(Schema::hasColumn('lessons', 'target_type'));
    }
}
