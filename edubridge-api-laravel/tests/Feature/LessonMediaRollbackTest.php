<?php

namespace Tests\Feature;

use App\Http\Controllers\LessonController;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Response;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class LessonMediaRollbackTest extends TestCase
{
    private array $history = [];
    private array $previousEnv = [];

    protected function setUp(): void
    {
        parent::setUp();
        foreach (['AWS_ENDPOINT' => 'https://r2.example.test', 'AWS_ACCESS_KEY_ID' => 'key', 'AWS_SECRET_ACCESS_KEY' => 'secret',
            'R2_MEDIA_BUCKET' => 'media', 'R2_MEDIA_PUBLIC_URL' => 'https://media.example.test'] as $key => $value) {
            $this->previousEnv[$key] = [$_ENV[$key] ?? null, $_SERVER[$key] ?? null];
            $_ENV[$key] = $_SERVER[$key] = $value;
        }
        Schema::create('lessons', function (Blueprint $table) {
            $table->id(); $table->string('title'); $table->text('content')->nullable();
            $table->integer('teacher_id'); $table->integer('disability_type_id')->nullable();
            $table->string('education_level')->nullable(); $table->string('target_type');
            $table->text('target_child_ids')->nullable(); $table->text('audio_description')->nullable();
        });
        Schema::create('media', function (Blueprint $table) {
            $table->id(); $table->integer('lesson_id'); $table->string('type'); $table->text('url');
        });
        DB::table('lessons')->insert(['id' => 1, 'title' => 'Existing', 'teacher_id' => 2, 'target_type' => 'everyone']);
        DB::table('media')->insert(['id' => 10, 'lesson_id' => 1, 'type' => 'image', 'url' => 'https://media.example.test/lessons/1/old.jpg']);
    }

    protected function tearDown(): void
    {
        foreach ($this->previousEnv as $key => [$env, $server]) {
            if ($env === null) unset($_ENV[$key]); else $_ENV[$key] = $env;
            if ($server === null) unset($_SERVER[$key]); else $_SERVER[$key] = $server;
        }
        Schema::dropIfExists('media'); Schema::dropIfExists('lessons');
        parent::tearDown();
    }

    private function storage(array $responses): void
    {
        $stack = HandlerStack::create(new MockHandler($responses));
        $stack->push(Middleware::history($this->history));
        $this->app->instance(Client::class, new Client(['handler' => $stack]));
    }

    private function request(int $fileCount): Request
    {
        $files = [];
        for ($i = 0; $i < $fileCount; $i++) $files[] = UploadedFile::fake()->create("image{$i}.jpg", 1, 'image/jpeg');
        $request = Request::create('/api/lessons/1', 'POST', ['title' => 'Updated'], [], ['images' => $files]);
        $request->attributes->set('jwt_user', (object) ['id' => 2, 'role' => 'teacher']);
        return $request;
    }

    public function test_failed_second_upload_restores_old_row_and_deletes_only_new_object(): void
    {
        $this->storage([new Response(200), new Response(500), new Response(204)]);
        $response = app(LessonController::class)->update($this->request(2), 1);
        $this->assertSame(500, $response->getStatusCode());
        $this->assertDatabaseHas('lessons', ['id' => 1, 'title' => 'Existing']);
        $this->assertDatabaseHas('media', ['id' => 10, 'url' => 'https://media.example.test/lessons/1/old.jpg']);
        $this->assertCount(3, $this->history);
        $this->assertSame('DELETE', $this->history[2]['request']->getMethod());
        $this->assertStringNotContainsString('old.jpg', (string) $this->history[2]['request']->getUri());
    }

    public function test_successful_replacement_deletes_old_object_after_upload(): void
    {
        $this->storage([new Response(200), new Response(204)]);
        $this->assertSame(200, app(LessonController::class)->update($this->request(1), 1)->getStatusCode());
        $this->assertDatabaseMissing('media', ['id' => 10]);
        $this->assertSame('PUT', $this->history[0]['request']->getMethod());
        $this->assertSame('DELETE', $this->history[1]['request']->getMethod());
        $this->assertStringContainsString('old.jpg', (string) $this->history[1]['request']->getUri());
    }
}
