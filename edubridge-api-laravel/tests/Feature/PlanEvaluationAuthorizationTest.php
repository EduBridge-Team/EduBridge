<?php

namespace Tests\Feature;

use App\Http\Controllers\PlanEvaluationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class PlanEvaluationAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('ministry_approvals', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id')->nullable();
        });

        Schema::create('plan_evaluations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('plan_id');
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('evaluator_id');
            $table->boolean('is_plan_appropriate');
            $table->text('notes_for_teacher')->nullable();
            $table->text('recommended_changes')->nullable();
            $table->timestamps();
            $table->unique(['plan_id', 'child_id', 'evaluator_id']);
        });

        DB::table('children')->insert([
            ['id' => 10, 'name' => 'طفل أ'],
            ['id' => 20, 'name' => 'طفل ب'],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 10,
            'specialist_id' => 3,
        ]);

        DB::table('ministry_approvals')->insert([
            ['id' => 100, 'child_id' => 10, 'teacher_id' => null],
            ['id' => 200, 'child_id' => 20, 'teacher_id' => null],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('plan_evaluations');
        Schema::dropIfExists('ministry_approvals');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('children');
        parent::tearDown();
    }

    public function test_plan_child_mismatch_is_rejected(): void
    {
        $response = app(PlanEvaluationController::class)->store(
            $this->request([
                'child_id' => 20,
                'is_plan_appropriate' => true,
            ], 3, 'specialist'),
            100
        );

        $this->assertSame(422, $response->getStatusCode());
        $this->assertDatabaseMissing('plan_evaluations', [
            'plan_id' => 100,
            'evaluator_id' => 3,
        ]);
    }

    public function test_assigned_specialist_can_evaluate_plan_for_its_actual_child(): void
    {
        $response = app(PlanEvaluationController::class)->store(
            $this->request([
                'child_id' => 10,
                'is_plan_appropriate' => true,
                'recommended_changes' => ['استمرار الخطة'],
            ], 3, 'specialist'),
            100
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('plan_evaluations', [
            'plan_id' => 100,
            'child_id' => 10,
            'evaluator_id' => 3,
        ]);
    }

    public function test_unassigned_specialist_cannot_evaluate_plan(): void
    {
        $response = app(PlanEvaluationController::class)->store(
            $this->request([
                'child_id' => 20,
                'is_plan_appropriate' => true,
            ], 3, 'specialist'),
            200
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    private function request(array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/plans/100/evaluate', 'POST', $payload);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
