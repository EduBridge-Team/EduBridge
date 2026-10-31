<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolEnrollmentDecisionController;
use Illuminate\Http\Request;
use Tests\TestCase;

class SchoolEnrollmentDecisionAccessTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        \Illuminate\Support\Facades\Schema::create('school_management_assignments', function (\Illuminate\Database\Schema\Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id'); $t->string('role'); $t->timestamp('ends_at')->nullable();
        });
    }

    protected function tearDown(): void
    {
        \Illuminate\Support\Facades\Schema::dropIfExists('school_management_assignments');
        parent::tearDown();
    }

    public function test_only_school_role_can_decide(): void
    {
        $request = Request::create('/api/school/enrollment-requests/1/decision', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'parent']);
        $this->assertSame(403, app(SchoolEnrollmentDecisionController::class)
            ->decide($request, 1)->getStatusCode());
    }

    public function test_missing_version_and_decision_are_rejected(): void
    {
        $request = Request::create('/api/school/enrollment-requests/1/decision', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'school']);
        $this->assertSame(422, app(SchoolEnrollmentDecisionController::class)
            ->decide($request, 1)->getStatusCode());
    }

    public function test_rejection_requires_nonempty_reason(): void
    {
        $request = Request::create('/api/school/enrollment-requests/1/decision', 'POST', [
            'expected_version' => 1, 'decision' => 'rejected', 'reason' => ' ',
        ]);
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'school']);
        $this->assertSame(422, app(SchoolEnrollmentDecisionController::class)
            ->decide($request, 1)->getStatusCode());
    }
}
