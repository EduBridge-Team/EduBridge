<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolDeputyManagementController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolDeputyManagementTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id();
            $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active')->default(true);
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email');
            $t->string('verification_status')->nullable();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
            $t->string('role');
            $t->unsignedBigInteger('appointed_by')->nullable();
            $t->timestamp('starts_at');
            $t->timestamp('ends_at')->nullable();
            $t->timestamps();
        });
        Schema::table('school_management_assignments', fn (Blueprint $t) => $t->json('permissions')->nullable());
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => null, 'is_active' => true],
            ['id' => 11, 'organization_id' => null, 'is_active' => true],
        ]);
        DB::table('users')->insert([
            ['id' => 20, 'name' => 'Director', 'email' => 'director@example.org', 'verification_status' => 'verified'],
            ['id' => 21, 'name' => 'Deputy', 'email' => 'deputy@example.org', 'verification_status' => 'verified'],
            ['id' => 22, 'name' => 'Unverified', 'email' => 'unverified@example.org', 'verification_status' => 'pending'],
            ['id' => 23, 'name' => 'Other director', 'email' => 'other@example.org', 'verification_status' => 'verified'],
        ]);
        $this->assign(10, 20, 'director');
        $this->assign(11, 23, 'director');
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('school_management_assignments');
        Schema::dropIfExists('users');
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    private function assign(int $school, int $user, string $role): int
    {
        return DB::table('school_management_assignments')->insertGetId([
            'school_id' => $school, 'user_id' => $user, 'role' => $role,
            'appointed_by' => null, 'starts_at' => now(), 'ends_at' => null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    private function request(int $user, array $data = []): Request
    {
        $request = Request::create('/api/school/deputies', 'POST', $data);
        $request->attributes->set('jwt_user', (object) ['id' => $user, 'role' => 'teacher']);
        return $request;
    }

    public function test_director_can_appoint_list_and_revoke_deputy(): void
    {
        $controller = app(SchoolDeputyManagementController::class);
        $response = $controller->store($this->request(20, ['user_email' => 'deputy@example.org']));
        $this->assertSame(201, $response->getStatusCode());
        $id = $response->getData(true)['assignment_id'];
        $this->assertCount(1, $controller->index($this->request(20))->getData(true)['deputies']);
        $this->assertTrue($controller->store($this->request(20, ['user_email' => 'deputy@example.org']))->getData(true)['unchanged']);
        $this->assertSame(404, $controller->revoke($this->request(23), $id)->getStatusCode());
        $this->assertSame(200, $controller->revoke($this->request(20), $id)->getStatusCode());
        $this->assertSame(404, $controller->revoke($this->request(20), $id)->getStatusCode());
        $this->assertCount(0, $controller->index($this->request(20))->getData(true)['deputies']);
    }

    public function test_non_director_and_unverified_identity_are_rejected(): void
    {
        $controller = app(SchoolDeputyManagementController::class);
        $this->assertSame(403, $controller->store($this->request(21, ['user_email' => 'deputy@example.org']))->getStatusCode());
        $this->assertSame(422, $controller->store($this->request(20, ['user_email' => 'unverified@example.org']))->getStatusCode());
        $this->assertSame(422, $controller->store($this->request(20, ['user_email' => 'director@example.org']))->getStatusCode());
    }

    public function test_revoked_director_and_multiple_directorships_are_rejected(): void
    {
        $controller = app(SchoolDeputyManagementController::class);
        $this->assign(11, 20, 'director');
        $this->assertSame(403, $controller->index($this->request(20))->getStatusCode());
        DB::table('school_management_assignments')->where('school_id', 11)->where('user_id', 20)->update(['ends_at' => now()]);
        DB::table('school_management_assignments')->where('school_id', 10)->where('user_id', 20)->update(['ends_at' => now()]);
        $this->assertSame(403, $controller->store($this->request(20, ['user_email' => 'deputy@example.org']))->getStatusCode());
    }

    public function test_deputy_permissions_are_explicit_and_can_be_withdrawn(): void
    {
        $controller = app(SchoolDeputyManagementController::class);
        $created = $controller->store($this->request(20, ['user_email' => 'deputy@example.org']));
        $id = $created->getData(true)['assignment_id'];
        $actor = $this->request(21);
        $this->assertNull(\App\Support\SchoolScopedAccess::resolve($actor, 'academic'));
        $request = $this->request(20, ['permissions' => ['academic']]);
        $this->assertSame(200, app(\App\Http\Controllers\SchoolDelegationController::class)->update($request, $id)->getStatusCode());
        $this->assertNotNull(\App\Support\SchoolScopedAccess::resolve($actor, 'academic'));
        $this->assertNull(\App\Support\SchoolScopedAccess::resolve($actor, 'enrollment'));
        $request = $this->request(20, ['permissions' => []]);
        $this->assertSame(200, app(\App\Http\Controllers\SchoolDelegationController::class)->update($request, $id)->getStatusCode());
        $this->assertNull(\App\Support\SchoolScopedAccess::resolve($actor, 'academic'));
        $this->assertNull(\App\Support\SchoolAdministration::directorSchool($actor));
    }
}
