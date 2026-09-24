<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class FreshPostgresMigrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_fresh_database_contains_core_edubridge_tables(): void
    {
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
