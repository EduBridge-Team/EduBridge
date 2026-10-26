<?php

namespace Tests\Feature;

use App\Http\Controllers\InteractiveLessonDraftController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Tests\TestCase;

class InteractiveLessonDraftTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('interactive_lesson_drafts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('author_id');
            $table->string('template_id');
            $table->string('title');
            $table->string('objective');
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('interactive_lesson_drafts');
        parent::tearDown();
    }

    private function requestFor(int $userId, string $role, array $payload = []): Request
    {
        $request = Request::create('/api/interactive-lesson-drafts', 'POST', $payload);
        $request->attributes->set('jwt_user', (object) ['id' => $userId, 'role' => $role]);
        return $request;
    }

    public function test_teacher_can_create_list_and_edit_only_own_draft(): void
    {
        $controller = new InteractiveLessonDraftController();
        $created = $controller->store($this->requestFor(3, 'teacher', [
            'template_id' => 'ar-alif-01', 'title' => 'الألف', 'objective' => 'تمييز الألف',
        ]));
        $this->assertSame(201, $created->getStatusCode());
        $draft = $created->getData(true)['draft'];
        $this->assertSame(1, $draft['version']);
        $this->assertCount(1, $controller->index($this->requestFor(3, 'teacher'))->getData(true)['drafts']);
        $this->assertCount(0, $controller->index($this->requestFor(4, 'specialist'))->getData(true)['drafts']);
        $payload = ['expected_version' => 1, 'title' => 'نسخة معدلة', 'objective' => 'نتاج جديد'];
        $this->assertSame(404, $controller->update(
            $this->requestFor(4, 'specialist', $payload), $draft['id'],
        )->getStatusCode());
        $updated = $controller->update($this->requestFor(3, 'teacher', $payload), $draft['id']);
        $this->assertSame(200, $updated->getStatusCode());
        $this->assertSame(2, $updated->getData(true)['draft']['version']);
        $this->assertSame(409, $controller->update(
            $this->requestFor(3, 'teacher', $payload), $draft['id'],
        )->getStatusCode());
    }

    public function test_unauthorized_role_and_blank_fields_are_rejected(): void
    {
        $controller = new InteractiveLessonDraftController();
        $payload = ['template_id' => 'ar-alif-01', 'title' => 'Title', 'objective' => 'Objective'];
        $this->assertSame(403, $controller->store($this->requestFor(1, 'parent', $payload))->getStatusCode());
        $this->assertSame(422, $controller->store($this->requestFor(2, 'teacher', [
            ...$payload, 'title' => ' ',
        ]))->getStatusCode());
        $this->assertSame(0, DB::table('interactive_lesson_drafts')->count());
    }
}
