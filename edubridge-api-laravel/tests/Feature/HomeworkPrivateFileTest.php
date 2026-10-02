<?php

namespace Tests\Feature;

use App\Http\Controllers\HomeworkController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class HomeworkPrivateFileTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('homeworks', function (Blueprint $table) { $table->id(); $table->integer('teacher_id'); });
        Schema::create('homework_submissions', function (Blueprint $table) {
            $table->id(); $table->integer('homework_id'); $table->integer('child_id');
            $table->text('file_urls')->nullable(); $table->text('file_url')->nullable();
        });
        Schema::create('child_parent', function (Blueprint $table) { $table->integer('child_id'); $table->integer('parent_id'); });
        DB::table('homeworks')->insert(['id' => 1, 'teacher_id' => 2]);
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 3]);
        DB::table('homework_submissions')->insert(['homework_id' => 1, 'child_id' => 10,
            'file_urls' => json_encode(['/api/private-files/homework/1/child/10/answer.pdf'])]);
    }

    protected function tearDown(): void
    {
        foreach (['homework_submissions', 'homeworks', 'child_parent'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    public function test_unrelated_parent_cannot_download_submission_even_with_its_url(): void
    {
        $request = Request::create('/api/private-files/homework/1/child/10/answer.pdf', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => 4, 'role' => 'parent']);
        $this->assertSame(403, app(HomeworkController::class)->file($request, 1, 10, 'answer.pdf')->getStatusCode());
    }

    public function test_related_parent_cannot_download_unreferenced_or_invalid_filename(): void
    {
        $request = Request::create('/api/private-files/homework/1/child/10/missing.pdf', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => 3, 'role' => 'parent']);
        $controller = app(HomeworkController::class);
        $this->assertSame(404, $controller->file($request, 1, 10, 'missing.pdf')->getStatusCode());
        $this->assertSame(403, $controller->file($request, 1, 10, '../answer.pdf')->getStatusCode());
    }
}
