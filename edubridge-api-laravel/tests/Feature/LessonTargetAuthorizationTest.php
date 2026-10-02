<?php

namespace Tests\Feature;

use App\Http\Controllers\LessonController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class LessonTargetAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
            $table->unsignedBigInteger('disability_type_id')->nullable();
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });

        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('category', 100)->nullable();
            $table->text('content')->nullable();
            $table->unsignedBigInteger('disability_type_id')->nullable();
            $table->string('education_level')->nullable();
            $table->unsignedBigInteger('teacher_id');
            $table->string('target_type')->nullable();
            $table->text('target_child_ids')->nullable();
            $table->text('audio_description')->nullable();
            $table->string('curriculum_status')->default('pending');
            $table->timestamps();
        });

        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');
            $table->string('type');
            $table->text('url');
        });

        DB::table('children')->insert([
            ['id' => 10, 'assigned_teacher_id' => 1],
            ['id' => 20, 'assigned_teacher_id' => null],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 20,
            'specialist_id' => 2,
        ]);

        DB::table('lessons')->insert([
            'id' => 100,
            'title' => 'درس قائم',
            'teacher_id' => 1,
            'target_type' => 'specificChildren',
            'target_child_ids' => json_encode([10]),
            'curriculum_status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('media');
        Schema::dropIfExists('lessons');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('children');

        parent::tearDown();
    }

    public function test_category_is_saved_updated_and_preserved_when_omitted(): void
    {
        $controller = app(LessonController::class);
        $response = $controller->store($this->request('POST', [
            'title' => 'تصنيف الدرس', 'category' => 'الرياضيات',
        ], 1, 'teacher'));
        $this->assertSame(201, $response->getStatusCode());
        $lesson = json_decode($response->getContent(), true)['lesson'];
        $this->assertSame('الرياضيات', $lesson['category']);
        $controller->update($this->request('PUT', ['category' => 'القراءة'], 1, 'teacher'), $lesson['id']);
        $controller->update($this->request('PUT', ['title' => 'عنوان جديد'], 1, 'teacher'), $lesson['id']);
        $this->assertDatabaseHas('lessons', ['id' => $lesson['id'], 'category' => 'القراءة']);
        $controller->update($this->request('PUT', ['category' => ''], 1, 'teacher'), $lesson['id']);
        $this->assertDatabaseHas('lessons', ['id' => $lesson['id'], 'category' => null]);
    }

    public function test_teacher_cannot_target_unassigned_child(): void
    {
        $response = app(LessonController::class)->store(
            $this->request('POST', [
                'title' => 'درس غير مصرح',
                'target_type' => 'specificChildren',
                'target_child_ids' => [20],
            ], 1, 'teacher')
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('lessons', ['title' => 'درس غير مصرح']);
    }

    public function test_teacher_can_target_assigned_child(): void
    {
        $response = app(LessonController::class)->store(
            $this->request('POST', [
                'title' => 'درس للطفل',
                'target_type' => 'specificChildren',
                'target_child_ids' => [10],
            ], 1, 'teacher')
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('lessons', [
            'title' => 'درس للطفل',
            'teacher_id' => 1,
        ]);
    }

    public function test_specialist_cannot_target_child_outside_team(): void
    {
        $response = app(LessonController::class)->store(
            $this->request('POST', [
                'title' => 'درس مختص غير مصرح',
                'target_type' => 'specificChildren',
                'target_child_ids' => [10],
            ], 2, 'specialist')
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_admin_can_target_any_existing_children(): void
    {
        $response = app(LessonController::class)->store(
            $this->request('POST', [
                'title' => 'درس الأدمن',
                'target_type' => 'specificChildren',
                'target_child_ids' => [10, 20],
            ], 99, 'admin')
        );

        $this->assertSame(201, $response->getStatusCode());
    }

    public function test_teacher_cannot_retarget_owned_lesson_to_unassigned_child(): void
    {
        $response = app(LessonController::class)->update(
            $this->request('PUT', [
                'target_type' => 'specificChildren',
                'target_child_ids' => [20],
            ], 1, 'teacher'),
            100
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_specialist_can_publish_parent_guidance(): void
    {
        $response = app(LessonController::class)->store($this->request('POST', [
            'title' => 'دعم الطفل في المنزل',
            'content' => 'إرشادات عملية لولي الأمر',
            'target_type' => 'parents',
        ], 2, 'specialist'));
        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('lessons', [
            'title' => 'دعم الطفل في المنزل', 'target_type' => 'parents', 'teacher_id' => 2,
        ]);
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/lessons', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }

    public function test_private_lesson_and_media_reject_unrelated_parent_but_allow_linked_parent(): void
    {
        $controller = app(LessonController::class);
        $outsider = $this->request('GET', [], 3, 'parent');
        $this->assertSame(403, $controller->show($outsider, 100)->getStatusCode());
        $this->assertSame(403, app(\App\Http\Controllers\MediaController::class)->index($outsider, 100)->getStatusCode());
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 3]);
        $this->assertSame(200, $controller->show($outsider, 100)->getStatusCode());
        $this->assertSame(200, app(\App\Http\Controllers\MediaController::class)->index($outsider, 100)->getStatusCode());
        $this->assertTrue(\App\Support\LessonVisibility::scope(DB::table('lessons'), (object) ['id' => 3, 'role' => 'parent'])->where('id', 100)->exists());
        $this->assertFalse(\App\Support\LessonVisibility::scope(DB::table('lessons'), (object) ['id' => 4, 'role' => 'parent'])->where('id', 100)->exists());
    }
}
