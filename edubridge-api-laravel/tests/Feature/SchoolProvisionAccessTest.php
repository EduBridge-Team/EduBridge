<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolProvisionController;
use Illuminate\Http\Request;
use Tests\TestCase;

class SchoolProvisionAccessTest extends TestCase
{
    public function test_non_admin_cannot_provision_independent_school(): void
    {
        $request = Request::create('/api/admin/school-accounts', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 3, 'role' => 'teacher']);

        $response = app(SchoolProvisionController::class)->independent($request);

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_school_provisioning_rejects_missing_fields(): void
    {
        $request = Request::create('/api/admin/school-accounts', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'admin']);

        $response = app(SchoolProvisionController::class)->independent($request);

        $this->assertSame(422, $response->getStatusCode());
        $this->assertArrayHasKey('errors', $response->getData(true));
    }

    public function test_institution_school_provisioning_requires_context(): void
    {
        $request = Request::create('/api/institutions/example/school-accounts', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 2, 'role' => 'institution']);

        $response = app(SchoolProvisionController::class)->affiliated($request, 'example');

        $this->assertSame(403, $response->getStatusCode());
    }
}
