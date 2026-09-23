<?php

namespace Tests\Feature;

use App\Http\Controllers\MediaController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MediaControllerAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');
            $table->string('type');
            $table->text('url');
        });

        DB::table('lessons')->insert([
            ['id' => 10, 'title' => 'درس 1', 'teacher_id' => 1],
            ['id' => 20, 'title' => 'درس 2', 'teacher_id' => 2],
        ]);

        DB::table('media')->insert([
            'id' => 100,
            'lesson_id' => 10,
            'type' => 'image',
            'url' => 'https://example.test/image.jpg',
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('media');
        Schema::dropIfExists('lessons');

        parent::tearDown();
    }

    public function test_other_teacher_cannot_add_media_to_someone_elses_lesson(): void
    {
        $response = app(MediaController::class)->store(
            $this->request('POST', [
                'type' => 'image',
                'url' => 'https://example.test/new.jpg',
            ], 2, 'teacher'),
            10
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('media', [
            'lesson_id' => 10,
            'url' => 'https://example.test/new.jpg',
        ]);
    }

    public function test_lesson_owner_can_add_media(): void
    {
        $response = app(MediaController::class)->store(
            $this->request('POST', [
                'type' => 'image',
                'url' => 'https://example.test/new.jpg',
            ], 1, 'teacher'),
            10
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('media', [
            'lesson_id' => 10,
            'url' => 'https://example.test/new.jpg',
        ]);
    }

    public function test_other_teacher_cannot_delete_media_from_someone_elses_lesson(): void
    {
        $response = app(MediaController::class)->destroy(
            $this->request('DELETE', [], 2, 'teacher'),
            100
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseHas('media', ['id' => 100]);
    }

    public function test_admin_can_delete_media_from_any_lesson(): void
    {
        $response = app(MediaController::class)->destroy(
            $this->request('DELETE', [], 99, 'admin'),
            100
        );

        $this->assertSame(200, $response->getStatusCode());
        $this->assertDatabaseMissing('media', ['id' => 100]);
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/media', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
