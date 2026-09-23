<?php

namespace Tests\Feature;

use App\Http\Controllers\PlanEvaluationController;
use App\Http\Controllers\WeeklyReportController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildSpecialistScopeTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        DB::table('children')->insert([
            ['id' => 10, 'name' => 'طفل أ', 'assigned_teacher_id' => null],
            ['id' => 20, 'name' => 'طفل ب', 'assigned_teacher_id' => null],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 10,
            'specialist_id' => 3,
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('children');

        parent::tearDown();
    }

    public function test_unassigned_specialist_cannot_write_weekly_report_for_child(): void
    {
        $request = $this->request('POST', [
            'child_id' => 20,
            'week_start' => now()->startOfWeek()->toDateString(),
        ], 3, 'specialist');

        $response = app(WeeklyReportController::class)->store($request);

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_unassigned_specialist_cannot_evaluate_plan_for_child(): void
    {
        $request = $this->request('POST', [
            'child_id' => 20,
            'is_plan_appropriate' => true,
        ], 3, 'specialist');

        $response = app(PlanEvaluationController::class)->store($request, 99);

        $this->assertSame(403, $response->getStatusCode());
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/test', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
