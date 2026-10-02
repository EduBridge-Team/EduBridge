<?php

namespace Tests\Feature;

use GuzzleHttp\Psr7\Response;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\Concerns\MocksPrivateR2;
use Tests\TestCase;

class PrivatizeLearningFilesTest extends TestCase
{
    use MocksPrivateR2;

    protected function setUp(): void
    {
        parent::setUp(); $this->configureR2();
        Schema::create('media', function (Blueprint $table) {
            $table->id(); $table->integer('lesson_id'); $table->text('url');
        });
        Schema::create('homework_submissions', function (Blueprint $table) {
            $table->id(); $table->integer('homework_id'); $table->integer('child_id');
            $table->text('file_url')->nullable(); $table->text('file_urls')->nullable();
        });
        DB::table('media')->insert(['id' => 1, 'lesson_id' => 10, 'url' => 'https://media.example.test/lessons/10/video.mp4']);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('homework_submissions'); Schema::dropIfExists('media');
        $this->restoreR2(); parent::tearDown();
    }

    public function test_preview_does_not_mutate_database_or_storage_and_external_urls_are_not_copied(): void
    {
        DB::table('media')->insert(['lesson_id' => 11, 'url' => 'https://external.example.test/lessons/11/a.mp4']);
        $this->assertSame(0, Artisan::call('edubridge:privatize-learning-files'));
        $this->assertStringContainsString('1 lesson objects', Artisan::output());
        $this->assertDatabaseHas('media', ['id' => 1, 'url' => 'https://media.example.test/lessons/10/video.mp4']);
        $this->assertCount(0, $this->r2History);
    }

    public function test_copy_failure_preserves_public_reference_and_object(): void
    {
        $this->mockR2([new Response(200, ['Content-Length' => '3'], 'abc'), new Response(500)]);
        $this->assertSame(1, Artisan::call('edubridge:privatize-learning-files', ['--apply' => true]));
        $this->assertDatabaseHas('media', ['id' => 1, 'url' => 'https://media.example.test/lessons/10/video.mp4']);
        $this->assertSame(['GET', 'PUT'], array_map(fn ($item) => $item['request']->getMethod(), $this->r2History));
    }

    public function test_delete_failure_can_be_retried_without_recopying_or_breaking_private_reference(): void
    {
        $this->mockR2([new Response(200, ['Content-Length' => '3'], 'abc'), new Response(200),
            new Response(200, ['Content-Length' => '3']), new Response(200), new Response(500)]);
        $this->assertSame(1, Artisan::call('edubridge:privatize-learning-files', ['--apply' => true]));
        $this->assertDatabaseHas('media', ['id' => 1, 'url' => '/api/private-files/lesson/10/video.mp4']);
        $this->r2History = [];
        $this->mockR2([new Response(200), new Response(204)]);
        $this->assertSame(0, Artisan::call('edubridge:privatize-learning-files', ['--apply' => true]));
        $this->assertSame(['HEAD', 'DELETE'], array_map(fn ($item) => $item['request']->getMethod(), $this->r2History));
    }

    public function test_shared_public_submission_is_retained_when_one_copy_fails(): void
    {
        DB::table('media')->delete();
        foreach ([10, 20] as $childId) DB::table('homework_submissions')->insert([
            'homework_id' => 100, 'child_id' => $childId, 'file_url' => 'https://media.example.test/homework/work.pdf',
            'file_urls' => json_encode(['https://media.example.test/homework/work.pdf']),
        ]);
        $this->mockR2([new Response(200, ['Content-Length' => '3'], 'abc'), new Response(200), new Response(200, ['Content-Length' => '3']), new Response(500)]);
        $this->assertSame(1, Artisan::call('edubridge:privatize-learning-files', ['--apply' => true]));
        $this->assertDatabaseHas('homework_submissions', ['child_id' => 10, 'file_url' => '/api/private-files/homework/100/child/10/work.pdf']);
        $this->assertDatabaseHas('homework_submissions', ['child_id' => 20, 'file_url' => 'https://media.example.test/homework/work.pdf']);
        $this->assertNotContains('DELETE', array_map(fn ($item) => $item['request']->getMethod(), $this->r2History));
    }
}
