<?php

namespace Tests\Feature;

use App\Http\Controllers\EvaluationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class EvaluationControllerAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('role');
        });

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('status')->default('pending');
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
            $table->timestamp('assigned_at')->nullable();
            $table->timestamp('created_at')->nullable();
            $table->unique(['child_id', 'teacher_id']);
        });

        Schema::create('evaluations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('evaluator_id')->nullable();
            $table->string('evaluation_type')->nullable();
            $table->text('cognitive_assessment')->nullable();
            $table->text('motor_assessment')->nullable();
            $table->text('emotional_assessment')->nullable();
            $table->text('social_assessment')->nullable();
            $table->text('recommendations')->nullable();
            $table->text('educational_plan')->nullable();
            $table->text('teaching_methods')->nullable();
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
            $table->timestamp('created_at')->nullable();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'معلم', 'role' => 'teacher'],
            ['id' => 2, 'name' => 'مختص', 'role' => 'specialist'],
            ['id' => 3, 'name' => 'معلم مستهدف', 'role' => 'teacher'],
            ['id' => 4, 'name' => 'مستخدم آخر', 'role' => 'parent'],
        ]);

        DB::table('children')->insert([
            'id' => 10,
            'name' => 'طفل',
            'status' => 'pending',
            'assigned_teacher_id' => null,
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('evaluations');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_teacher_cannot_assign_teacher_from_evaluation(): void
    {
        $response = app(EvaluationController::class)->store(
            $this->request(1, 'teacher', ['assigned_teacher_id' => 3]),
            10
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('evaluations', [
            'child_id' => 10,
            'assigned_teacher_id' => 3,
        ]);
    }

    public function test_specialist_can_assign_valid_teacher_from_evaluation(): void
    {
        $response = app(EvaluationController::class)->store(
            $this->request(2, 'specialist', [
                'evaluation_type' => 'educational',
                'assigned_teacher_id' => 3,
            ]),
            10
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('children', [
            'id' => 10,
            'assigned_teacher_id' => 3,
            'status' => 'assigned',
        ]);
        $this->assertDatabaseHas('child_teacher', [
            'child_id' => 10,
            'teacher_id' => 3,
        ]);
    }

    public function test_assignment_rejects_non_teacher_account(): void
    {
        $response = app(EvaluationController::class)->store(
            $this->request(2, 'specialist', ['assigned_teacher_id' => 4]),
            10
        );

        $this->assertSame(422, $response->getStatusCode());
        $this->assertDatabaseHas('children', [
            'id' => 10,
            'assigned_teacher_id' => null,
        ]);
    }

    private function request(int $id, string $role, array $payload): Request
    {
        $request = Request::create('/api/evaluations/child/10', 'POST', $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
