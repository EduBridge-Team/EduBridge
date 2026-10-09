<?php

namespace Tests\Feature;

use App\Http\Controllers\MediaController;
use Tests\Concerns\MocksPrivateR2;
use GuzzleHttp\Psr7\Response;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MediaControllerAuthorizationTest extends TestCase
{
    use MocksPrivateR2;

    protected function setUp(): void
    {
        parent::setUp();
        $this->configureR2();

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
        $this->restoreR2();

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

    public function test_failed_r2_delete_preserves_media_reference(): void
    {
        DB::table('media')->where('id', 100)->update([
            'url' => '/api/private-files/lesson/10/image.jpg',
        ]);
        $this->mockR2([new Response(500)]);

        $response = app(MediaController::class)->destroy(
            $this->request('DELETE', [], 1, 'teacher'), 100
        );

        $this->assertSame(502, $response->getStatusCode());
        $this->assertDatabaseHas('media', [
            'id' => 100, 'url' => '/api/private-files/lesson/10/image.jpg',
        ]);
        $this->assertCount(1, $this->r2History);
        $this->assertSame('DELETE', $this->r2History[0]['request']->getMethod());
    }

    public function test_successful_r2_delete_removes_media_reference(): void
    {
        DB::table('media')->where('id', 100)->update([
            'url' => '/api/private-files/lesson/10/image.jpg',
        ]);
        $this->mockR2([new Response(204)]);

        $response = app(MediaController::class)->destroy(
            $this->request('DELETE', [], 1, 'teacher'), 100
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
