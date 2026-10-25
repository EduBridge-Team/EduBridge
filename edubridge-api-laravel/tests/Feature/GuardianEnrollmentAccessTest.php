<?php

namespace Tests\Feature;

use App\Http\Controllers\GuardianEnrollmentHistoryController;
use App\Http\Controllers\GuardianEnrollmentCancellationController;
use Illuminate\Http\Request;
use Tests\TestCase;

class GuardianEnrollmentAccessTest extends TestCase
{
    public function test_non_parent_cannot_see_history(): void
    {
        $request = Request::create('/api/parent/children/1/enrollment-requests', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'teacher']);

        $this->assertSame(403, app(GuardianEnrollmentHistoryController::class)
            ->index($request, 1)->getStatusCode());
    }

    public function test_cancellation_requires_parent_role_and_version(): void
    {
        $request = Request::create('/api/parent/children/1/enrollment-requests/1/cancel', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'teacher']);
        $this->assertSame(403, app(GuardianEnrollmentCancellationController::class)
            ->cancel($request, 1, 1)->getStatusCode());

        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);
        $this->assertSame(422, app(GuardianEnrollmentCancellationController::class)
            ->cancel($request, 1, 1)->getStatusCode());
    }
}
