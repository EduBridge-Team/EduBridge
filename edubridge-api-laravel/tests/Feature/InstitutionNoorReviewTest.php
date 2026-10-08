<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionCurriculumController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionNoorReviewTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
        });
        Schema::create('organization_user', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
            $table->unsignedBigInteger('user_id');
            $table->string('role');
            $table->boolean('is_active')->default(true);
        });
        Schema::create('noor_lesson_generations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id');
            $table->unsignedBigInteger('requested_by');
            $table->string('status');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
        });
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => 1],
            ['id' => 20, 'organization_id' => 2],
        ]);
        DB::table('organization_user')->insert([
            ['organization_id' => 1, 'user_id' => 100, 'role' => 'teacher', 'is_active' => true],
            ['organization_id' => 1, 'user_id' => 101, 'role' => 'teacher', 'is_active' => true],
            ['organization_id' => 1, 'user_id' => 200, 'role' => 'admin', 'is_active' => true],
        ]);
        DB::table('noor_lesson_generations')->insert([
            ['id' => 1, 'school_id' => 10, 'requested_by' => 100, 'status' => 'draft'],
            ['id' => 2, 'school_id' => 20, 'requested_by' => 100, 'status' => 'draft'],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('noor_lesson_generations');
        Schema::dropIfExists('organization_user');
        Schema::dropIfExists('schools');
        parent::tearDown();
    }

    private function approvalRequest(int $userId): Request
    {
        $request = Request::create('/api/institutions/jabalia/schools/10/teaching/generations/1/approve', 'POST');
        $request->attributes->set('organization', (object) ['id' => 1, 'slug' => 'jabalia']);
        $request->attributes->set('jwt_user', (object) ['id' => $userId]);
        return $request;
    }

    public function test_teacher_can_approve_own_draft_only_once(): void
    {
        $controller = app(InstitutionCurriculumController::class);
        $this->assertSame(200, $controller->approveGeneration($this->approvalRequest(100), 'jabalia', 10, 1)->getStatusCode());
        $this->assertDatabaseHas('noor_lesson_generations', ['id' => 1, 'status' => 'approved', 'approved_by' => 100]);
        $this->assertSame(409, $controller->approveGeneration($this->approvalRequest(100), 'jabalia', 10, 1)->getStatusCode());
    }

    public function test_teacher_cannot_approve_another_teachers_draft(): void
    {
        $response = app(InstitutionCurriculumController::class)
            ->approveGeneration($this->approvalRequest(101), 'jabalia', 10, 1);
        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseHas('noor_lesson_generations', ['id' => 1, 'status' => 'draft']);
    }

    public function test_admin_can_approve_school_draft(): void
    {
        $response = app(InstitutionCurriculumController::class)
            ->approveGeneration($this->approvalRequest(200), 'jabalia', 10, 1);
        $this->assertSame(200, $response->getStatusCode());
        $this->assertDatabaseHas('noor_lesson_generations', ['id' => 1, 'approved_by' => 200]);
    }

    public function test_approval_cannot_cross_school_or_organization_boundary(): void
    {
        $response = app(InstitutionCurriculumController::class)
            ->approveGeneration($this->approvalRequest(200), 'jabalia', 10, 2);
        $this->assertSame(404, $response->getStatusCode());
        $response = app(InstitutionCurriculumController::class)
            ->approveGeneration($this->approvalRequest(200), 'jabalia', 20, 2);
        $this->assertSame(404, $response->getStatusCode());
    }
}
