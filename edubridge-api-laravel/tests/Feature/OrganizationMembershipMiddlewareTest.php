<?php

namespace Tests\Feature;

use App\Http\Middleware\OrganizationMembershipMiddleware;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class OrganizationMembershipMiddlewareTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->boolean('is_active')->default(true);
        });

        Schema::create('organization_user', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
            $table->unsignedBigInteger('user_id');
            $table->string('role');
            $table->boolean('is_active')->default(true);
        });

        DB::table('organizations')->insert([
            ['id' => 1, 'name' => 'Jabalia', 'slug' => 'jabalia', 'is_active' => true],
            ['id' => 2, 'name' => 'Other', 'slug' => 'other', 'is_active' => true],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('organization_user');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    public function test_active_tenant_admin_membership_is_accepted_and_bound(): void
    {
        DB::table('organization_user')->insert([
            'organization_id' => 1,
            'user_id' => 10,
            'role' => 'admin',
            'is_active' => true,
        ]);

        $request = $this->tenantRequest('jabalia', (object) ['id' => 10, 'role' => 'institution']);

        $response = app(OrganizationMembershipMiddleware::class)->handle(
            $request,
            function (Request $request) {
                $this->assertSame(1, $request->attributes->get('organization')->id);
                $this->assertSame('admin', $request->attributes->get('organization_role'));
                return response()->json(['ok' => true]);
            },
            'owner', 'admin', 'school_admin'
        );

        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_membership_in_another_tenant_does_not_grant_access(): void
    {
        DB::table('organization_user')->insert([
            'organization_id' => 2,
            'user_id' => 10,
            'role' => 'admin',
            'is_active' => true,
        ]);

        $request = $this->tenantRequest('jabalia', (object) ['id' => 10, 'role' => 'institution']);
        $response = app(OrganizationMembershipMiddleware::class)->handle(
            $request,
            fn () => response()->json(['ok' => true]),
            'owner', 'admin', 'school_admin'
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_non_admin_organization_role_is_rejected_for_admin_routes(): void
    {
        DB::table('organization_user')->insert([
            'organization_id' => 1,
            'user_id' => 10,
            'role' => 'teacher',
            'is_active' => true,
        ]);

        $request = $this->tenantRequest('jabalia', (object) ['id' => 10, 'role' => 'teacher']);
        $response = app(OrganizationMembershipMiddleware::class)->handle(
            $request,
            fn () => response()->json(['ok' => true]),
            'owner', 'admin', 'school_admin'
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_platform_admin_is_bound_to_explicit_tenant_without_membership(): void
    {
        $request = $this->tenantRequest('jabalia', (object) ['id' => 99, 'role' => 'admin']);

        $response = app(OrganizationMembershipMiddleware::class)->handle(
            $request,
            function (Request $request) {
                $this->assertSame(1, $request->attributes->get('organization')->id);
                $this->assertSame('platform_admin', $request->attributes->get('organization_role'));
                return response()->json(['ok' => true]);
            },
            'owner', 'admin', 'school_admin'
        );

        $this->assertSame(200, $response->getStatusCode());
    }

    private function tenantRequest(string $slug, object $user): Request
    {
        $request = Request::create('/api/institutions/'.$slug.'/schools', 'GET');
        $request->attributes->set('jwt_user', $user);
        $request->setRouteResolver(fn () => new class($slug) {
            public function __construct(private string $slug) {}
            public function parameter(string $name, mixed $default = null): mixed
            {
                return $name === 'organizationSlug' ? $this->slug : $default;
            }
        });

        return $request;
    }
}
