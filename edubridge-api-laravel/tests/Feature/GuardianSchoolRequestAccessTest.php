<?php

namespace Tests\Feature;

use App\Http\Controllers\GuardianSchoolRequestController;
use Illuminate\Http\Request;
use Tests\TestCase;

class GuardianSchoolRequestAccessTest extends TestCase
{
    public function test_non_parent_cannot_search_or_request(): void
    {
        $request = Request::create('/api/parent/enrollment-schools', 'GET', ['q' => 'school']);
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'teacher']);
        $this->assertSame(403, app(GuardianSchoolRequestController::class)->schools($request)->getStatusCode());

        $request = Request::create('/api/parent/children/10/enrollment-requests', 'POST', ['school_id' => 3]);
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'teacher']);
        $this->assertSame(403, app(GuardianSchoolRequestController::class)->submit($request, 10)->getStatusCode());
    }

    public function test_search_requires_valid_query_length(): void
    {
        $request = Request::create('/api/parent/enrollment-schools', 'GET', ['q' => 'a']);
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);
        $this->assertSame(422, app(GuardianSchoolRequestController::class)->schools($request)->getStatusCode());
    }

    public function test_submission_requires_school_identifier(): void
    {
        $request = Request::create('/api/parent/children/10/enrollment-requests', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);
        $this->assertSame(422, app(GuardianSchoolRequestController::class)->submit($request, 10)->getStatusCode());
    }
}
