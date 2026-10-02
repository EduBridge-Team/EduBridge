<?php

namespace Tests\Feature;

use App\Http\Controllers\ChildController;
use App\Http\Controllers\ChildLessonController;
use App\Http\Controllers\LessonController;
use Illuminate\Http\Request;
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
            'engagement_events',
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

        $this->assertTrue(Schema::hasIndex('notifications', 'notifications_user_cursor_index'));
        $this->assertTrue(Schema::hasIndex('notifications', 'notifications_user_unread_index'));
        $this->assertTrue(Schema::hasColumn('users', 'role'));
        $this->assertTrue(Schema::hasColumn('users', 'password_hash'));
        $this->assertTrue(Schema::hasColumn('sessions', 'learning_support_request_id'));
        $this->assertTrue(Schema::hasColumn('lessons', 'target_type'));

        $userId = DB::table('users')->insertGetId([
            'name' => 'Admin', 'email' => 'batch-test@example.com', 'password' => 'unused', 'role' => 'admin',
        ]);
        $childId = DB::table('children')->insertGetId(['name' => 'Batch child']);
        $planId = DB::table('ministry_approvals')->insertGetId([
            'child_id' => $childId, 'submitted_by' => $userId, 'status' => 'approved',
            'educational_plan' => 'Approved plan', 'teaching_methods' => '["visual"]',
            'reviewed_at' => now(), 'created_at' => now(),
        ]);
        for ($i = 0; $i < 30; $i++) {
            $lessonId = DB::table('lessons')->insertGetId(['title' => 'Batch lesson '.$i]);
            DB::table('media')->insert(['lesson_id' => $lessonId, 'type' => 'image', 'url' => 'https://example.com/'.$i.'.png']);
        }
        $request = Request::create('/api/test');
        $request->attributes->set('jwt_user', (object) ['id' => $userId, 'role' => 'admin']);
        DB::enableQueryLog();
        try {
            DB::flushQueryLog();
            $children = app(ChildController::class)->index($request);
            $this->assertSame(200, $children->getStatusCode());
            $this->assertCount(3, DB::getQueryLog());
            $this->assertSame($planId, $children->getData(true)['children'][0]['current_plan_id']);
            DB::flushQueryLog();
            $lessons = app(LessonController::class)->index($request);
            $this->assertSame(200, $lessons->getStatusCode());
            $this->assertCount(2, DB::getQueryLog());
            $this->assertCount(30, $lessons->getData(true)['lessons']);
            $this->assertCount(1, $lessons->getData(true)['lessons'][0]['media']);
            DB::flushQueryLog();
            $request->query->set('q', 'Batch lesson');
            $search = app(LessonController::class)->search($request);
            $this->assertSame(200, $search->getStatusCode());
            $this->assertCount(2, DB::getQueryLog());
            $this->assertCount(30, $search->getData(true)['lessons']);
            DB::flushQueryLog();
            $childLessons = app(ChildLessonController::class)->lessons($request, $childId);
            $this->assertSame(200, $childLessons->getStatusCode());
            $this->assertCount(3, DB::getQueryLog());
            $this->assertCount(30, $childLessons->getData(true)['lessons']);
        } finally {
            DB::disableQueryLog();
        }
    }
}
