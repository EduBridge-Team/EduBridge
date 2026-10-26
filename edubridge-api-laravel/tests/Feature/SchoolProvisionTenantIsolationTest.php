<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolProvisionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolProvisionTenantIsolationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organization_user', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
            $table->unsignedBigInteger('user_id');
            $table->string('role');
            $table->boolean('is_active');
        });
        DB::table('organization_user')->insert([
            ['organization_id' => 1, 'user_id' => 11, 'role' => 'owner', 'is_active' => true],
            ['organization_id' => 2, 'user_id' => 11, 'role' => 'admin', 'is_active' => false],
            ['organization_id' => 2, 'user_id' => 12, 'role' => 'school_admin', 'is_active' => true],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('organization_user');
        parent::tearDown();
    }

    private function tryCreate(int $userId, string $role, int $tenantId): int
    {
        $request = Request::create('/api/institutions/example/school-accounts', 'POST', [
            'name' => 'Test school', 'email' => 'example@school.test',
            'password' => 'change-this-password', 'password_confirmation' => 'change-this-password',
        ]);
        $request->attributes->set('jwt_user', (object) ['id' => $userId, 'role' => $role]);
        $request->attributes->set('organization', (object) ['id' => $tenantId]);
        return app(SchoolProvisionController::class)->affiliated($request, 'example')->getStatusCode();
    }

    public function test_active_owner_of_another_organization_cannot_create_school(): void
    {
        $this->assertSame(403, $this->tryCreate(11, 'institution', 3));
    }

    public function test_inactive_membership_does_not_allow_school_creation(): void
    {
        $this->assertSame(403, $this->tryCreate(11, 'institution', 2));
    }

    public function test_school_admin_membership_cannot_provision_school_account(): void
    {
        $this->assertSame(403, $this->tryCreate(12, 'institution', 2));
    }

    public function test_non_institution_role_cannot_use_institution_provision_route(): void
    {
        $this->assertSame(403, $this->tryCreate(11, 'teacher', 1));
    }
}
