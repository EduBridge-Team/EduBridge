<?php

namespace Tests\Feature;

use App\Http\Controllers\ProgressController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ProgressControllerAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });

        Schema::create('progress', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('lesson_id');
            $table->string('status')->nullable();
            $table->integer('score')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->unique(['child_id', 'lesson_id']);
        });

        DB::table('children')->insert([
            ['id' => 10, 'assigned_teacher_id' => null],
            ['id' => 20, 'assigned_teacher_id' => null],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 10,
            'specialist_id' => 3,
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('progress');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('children');

        parent::tearDown();
    }

    public function test_specialist_can_update_progress_for_assigned_child(): void
    {
        $response = app(ProgressController::class)->store(
            $this->request(3, 'specialist', [
                'child_id' => 10,
                'lesson_id' => 100,
                'status' => 'done',
                'score' => 90,
            ])
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('progress', [
            'child_id' => 10,
            'lesson_id' => 100,
            'status' => 'done',
            'score' => 90,
        ]);
    }

    public function test_specialist_cannot_update_progress_for_unassigned_child(): void
    {
        $response = app(ProgressController::class)->store(
            $this->request(3, 'specialist', [
                'child_id' => 20,
                'lesson_id' => 100,
                'status' => 'done',
            ])
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('progress', [
            'child_id' => 20,
            'lesson_id' => 100,
        ]);
    }

    private function request(int $id, string $role, array $payload): Request
    {
        $request = Request::create('/api/progress', 'POST', $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
