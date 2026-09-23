<?php

namespace Tests\Feature;

use App\Http\Controllers\MinistryApprovalController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MinistryApprovalAuthorizationTest extends TestCase
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
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('ministry_approvals', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('evaluation_id')->nullable();
            $table->unsignedBigInteger('submitted_by');
            $table->unsignedBigInteger('teacher_id')->nullable();
            $table->text('educational_plan');
            $table->text('cognitive_assessment')->nullable();
            $table->text('motor_assessment')->nullable();
            $table->text('emotional_assessment')->nullable();
            $table->text('social_assessment')->nullable();
            $table->text('recommendations')->nullable();
            $table->text('teaching_methods')->nullable();
            $table->string('status')->default('pending');
            $table->text('review_reason')->nullable();
            $table->unsignedBigInteger('reviewed_by')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('title');
            $table->text('message');
            $table->string('type')->nullable();
            $table->timestamp('created_at')->nullable();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'معلم 1', 'role' => 'teacher'],
            ['id' => 2, 'name' => 'معلم 2', 'role' => 'teacher'],
            ['id' => 3, 'name' => 'مختص', 'role' => 'specialist'],
            ['id' => 4, 'name' => 'ولي أمر', 'role' => 'parent'],
            ['id' => 5, 'name' => 'وزارة', 'role' => 'ministry'],
            ['id' => 6, 'name' => 'أدمن', 'role' => 'admin'],
        ]);

        DB::table('children')->insert([
            ['id' => 10, 'name' => 'طفل أ', 'assigned_teacher_id' => 1],
            ['id' => 20, 'name' => 'طفل ب', 'assigned_teacher_id' => 2],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 10,
            'specialist_id' => 3,
        ]);

        DB::table('child_parent')->insert([
            'child_id' => 10,
            'parent_id' => 4,
        ]);

        DB::table('ministry_approvals')->insert([
            'id' => 100,
            'child_id' => 10,
            'submitted_by' => 1,
            'educational_plan' => 'خطة',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('ministry_approvals');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_teacher_cannot_submit_plan_for_unassigned_child(): void
    {
        $response = app(MinistryApprovalController::class)->store(
            $this->request('POST', [
                'child_id' => 20,
                'educational_plan' => 'خطة غير مصرح بها',
            ], 1, 'teacher')
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('ministry_approvals', [
            'child_id' => 20,
            'submitted_by' => 1,
        ]);
    }

    public function test_assigned_specialist_can_submit_plan_for_child(): void
    {
        $response = app(MinistryApprovalController::class)->store(
            $this->request('POST', [
                'child_id' => 10,
                'educational_plan' => 'خطة المختص',
            ], 3, 'specialist')
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('ministry_approvals', [
            'child_id' => 10,
            'submitted_by' => 3,
            'educational_plan' => 'خطة المختص',
        ]);
    }

    public function test_parent_can_read_status_for_own_child_only(): void
    {
        $allowed = app(MinistryApprovalController::class)->childStatus(
            $this->request('GET', [], 4, 'parent'),
            10
        );
        $blocked = app(MinistryApprovalController::class)->childStatus(
            $this->request('GET', [], 4, 'parent'),
            20
        );

        $this->assertSame(200, $allowed->getStatusCode());
        $this->assertSame(403, $blocked->getStatusCode());
    }

    public function test_invalid_teacher_assignment_is_rejected(): void
    {
        $response = app(MinistryApprovalController::class)->store(
            $this->request('POST', [
                'child_id' => 10,
                'educational_plan' => 'خطة',
                'teacher_id' => 3,
            ], 6, 'admin')
        );

        $this->assertSame(422, $response->getStatusCode());
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/ministry/approvals', $method, $payload);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
