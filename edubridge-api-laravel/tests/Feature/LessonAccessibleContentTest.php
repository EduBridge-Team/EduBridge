<?php

namespace Tests\Feature;

use App\Http\Controllers\LessonController;
use App\Http\Controllers\Concerns\ChildLessonHelpers;
use App\Support\LessonAccessibleContent;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class LessonAccessibleContentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('lessons', function (Blueprint $table) {
            $table->id(); $table->string('title'); $table->text('content')->nullable();
            $table->integer('teacher_id'); $table->integer('disability_type_id')->nullable();
            $table->string('education_level')->nullable(); $table->string('target_type');
            $table->text('target_child_ids')->nullable(); $table->text('audio_description')->nullable();
            $table->json('image_descriptions')->nullable(); $table->text('real_life_example')->nullable();
        });
        Schema::create('media', function (Blueprint $table) {
            $table->id(); $table->integer('lesson_id'); $table->string('type'); $table->text('url');
        });
        DB::table('lessons')->insert(['id' => 1, 'title' => 'Counting', 'teacher_id' => 2, 'target_type' => 'everyone']);
        foreach ([3, 7] as $id) {
            DB::table('media')->insert(['id' => $id, 'lesson_id' => 1, 'type' => 'image', 'url' => "https://example.com/$id.jpg"]);
        }
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('media'); Schema::dropIfExists('lessons');
        parent::tearDown();
    }

    private function request(array $fields, int $teacherId = 2): Request
    {
        $request = Request::create('/api/lessons/1', 'POST', $fields);
        $request->attributes->set('jwt_user', (object) ['id' => $teacherId, 'role' => 'teacher']);
        return $request;
    }

    public function test_descriptions_keep_image_order_and_are_shared_with_child_reading(): void
    {
        $request = $this->request(['image_descriptions' => json_encode(['ثلاث تفاحات', '']), 'real_life_example' => ' نعد الملاعق ']);
        $response = app(LessonController::class)->update($request, 1);
        $this->assertSame(200, $response->getStatusCode());
        $data = $response->getData(true)['lesson'];
        $this->assertSame(['ثلاث تفاحات', null], $data['image_descriptions']);
        $this->assertSame(['https://example.com/3.jpg', 'https://example.com/7.jpg'], $data['images']);
        $this->assertSame('نعد الملاعق', $data['real_life_example']);
        $serializer = new class {
            use ChildLessonHelpers;
            public function read(Request $request, object $lesson): array { return $this->serializeChildLesson($request, $lesson); }
        };
        $child = $serializer->read($request, DB::table('lessons')->find(1));
        $this->assertSame($data['image_descriptions'], $child['image_descriptions']);
        $this->assertSame($data['real_life_example'], $child['real_life_example']);
        app(LessonController::class)->update($this->request(['title' => 'New title']), 1);
        $this->assertDatabaseHas('lessons', ['id' => 1, 'real_life_example' => 'نعد الملاعق']);
        $this->assertSame(['ثلاث تفاحات', null], json_decode(DB::table('lessons')->find(1)->image_descriptions, true));
    }

    public function test_replacing_images_without_descriptions_clears_old_alignment(): void
    {
        $payload = LessonAccessibleContent::payload($this->request([]), 1, true);
        $this->assertSame([null], json_decode($payload['image_descriptions'], true));
        $this->assertSame([], LessonAccessibleContent::payload($this->request([]), 0));
    }

    public function test_more_descriptions_than_images_are_rejected_before_mutation(): void
    {
        $this->expectException(ValidationException::class);
        app(LessonController::class)->update($this->request(['image_descriptions' => ['a', 'b', 'c']]), 1);
    }

    public function test_invalid_json_is_rejected(): void
    {
        $this->expectException(ValidationException::class);
        LessonAccessibleContent::validate($this->request(['image_descriptions' => '{broken']));
    }

    public function test_non_author_cannot_change_accessible_content(): void
    {
        $response = app(LessonController::class)->update($this->request(['real_life_example' => 'Changed'], 8), 1);
        $this->assertSame(403, $response->getStatusCode());
        $this->assertNull(DB::table('lessons')->find(1)->real_life_example);
    }

    public function test_old_lessons_have_honest_empty_descriptions(): void
    {
        $this->assertSame([null, null], LessonAccessibleContent::descriptions(null, 2));
        $this->assertSame([null, null], LessonAccessibleContent::descriptions('{invalid', 2));
        $this->assertSame(['وصف', null], LessonAccessibleContent::descriptions('["وصف"]', 2));
    }
}
