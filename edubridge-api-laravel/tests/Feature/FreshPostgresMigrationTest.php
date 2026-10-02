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

        $this->assertTrue(Schema::hasIndex('children', 'children_name_page_index'));
        $this->assertTrue(Schema::hasIndex('lessons', 'lessons_created_page_index'));
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

    public function test_paged_directories_use_real_postgres_role_scopes_and_literal_search(): void
    {
        if (DB::getDriverName() !== 'pgsql') $this->markTestSkipped('Requires PostgreSQL.');
        Artisan::call('migrate:fresh', ['--force' => true]);
        foreach ([1 => 'parent', 2 => 'teacher', 3 => 'specialist', 4 => 'ministry', 21 => 'teacher', 99 => 'admin'] as $id => $role) {
            DB::table('users')->insert(['id' => $id, 'name' => $role, 'email' => "page-$id@example.com", 'password' => 'unused', 'role' => $role]);
        }
        foreach (range(1, 45) as $id) {
            DB::table('children')->insert(['id' => $id, 'name' => $id === 1 ? 'Far 100%' : 'Same child', 'assigned_teacher_id' => $id <= 40 ? 2 : 21]);
            DB::table('child_parent')->insert(['child_id' => $id, 'parent_id' => $id <= 40 ? 1 : 99]);
        }
        DB::table('child_teacher')->insert(['child_id' => 1, 'teacher_id' => 21]);
        DB::table('child_specialist')->insert(['child_id' => 1, 'specialist_id' => 3, 'specialty' => 'educational']);
        foreach (range(1, 70) as $id) {
            DB::table('lessons')->insert([
                'id' => $id, 'title' => $id === 1 ? 'Far 100%' : 'Lesson', 'teacher_id' => 99,
                'target_type' => $id === 65 ? 'parents' : ($id >= 69 ? 'specificChildren' : 'everyone'),
                'target_child_ids' => json_encode([$id === 70 ? 45 : 1]), 'created_at' => '2026-10-02 12:00:00',
            ]);
            DB::table('media')->insert(['lesson_id' => $id, 'type' => 'image', 'url' => 'https://example.com/image.png']);
        }
        $request = Request::create('/api/list', 'GET', ['page' => 1, 'per_page' => 3]);
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'parent']);
        $children = app(ChildController::class)->index($request)->getData(true);
        $this->assertSame(40, $children['pagination']['total']);
        $this->assertCount(3, $children['children']);
        $this->assertSame(40, $children['summary']['total_children']);
        $request->query->set('q', '100%');
        $this->assertSame([1], array_column(app(ChildController::class)->index($request)->getData(true)['children'], 'id'));
        $this->assertSame([1], array_column(app(LessonController::class)->index($request)->getData(true)['lessons'], 'id'));
        $request->query->remove('q');
        foreach ([[1, 'parent', 68], [2, 'teacher', 69], [3, 'specialist', 69], [4, 'ministry', 70], [21, 'teacher', 70]] as [$id, $role, $total]) {
            $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
            DB::enableQueryLog(); DB::flushQueryLog();
            $data = app(LessonController::class)->index($request)->getData(true);
            $queries = DB::getQueryLog(); DB::disableQueryLog();
            $this->assertSame($total, $data['pagination']['total']);
            $this->assertCount(3, $data['lessons']);
            $this->assertCount(3, $queries); // count + page + batch media, no assignment prefetch.
        }
    }
}
