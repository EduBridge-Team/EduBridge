<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolContextController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolContextTest extends TestCase
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
            $t->string('name');
            $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active')->default(true);
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
            $t->string('role');
            $t->timestamp('ends_at')->nullable();
        });
        DB::table('organizations')->insert(['id' => 4, 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 10, 'name' => 'Independent', 'organization_id' => null, 'is_active' => true],
            ['id' => 11, 'name' => 'Affiliated', 'organization_id' => 4, 'is_active' => true],
        ]);
        DB::table('school_accounts')->insert([
            ['school_id' => 10, 'user_id' => 20],
            ['school_id' => 11, 'user_id' => 21],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('school_management_assignments');
        Schema::dropIfExists('school_accounts');
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    private function context(int $userId, string $role = 'school'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/context', 'GET', ['school_id' => 999]);
        $request->attributes->set('jwt_user', (object) ['id' => $userId, 'role' => $role]);
        return app(SchoolContextController::class)->show($request);
    }

    public function test_only_linked_school_account_can_resolve_context(): void
    {
        $this->assertSame(403, $this->context(20, 'teacher')->getStatusCode());
        $this->assertSame(403, $this->context(99)->getStatusCode());
        $data = $this->context(20)->getData(true);
        $this->assertSame(10, $data['school']['id']);
        $this->assertNull($data['school']['organization_id']);
    }

    public function test_active_personal_director_can_resolve_assigned_school(): void
    {
        DB::table('school_management_assignments')->insert([
            'school_id' => 10, 'user_id' => 30, 'role' => 'director', 'ends_at' => null,
        ]);
        $this->assertSame(10, $this->context(30, 'teacher')->getData(true)['school']['id']);
        $this->assertSame(403, $this->context(31, 'teacher')->getStatusCode());
    }

    public function test_revoked_or_ambiguous_director_assignments_are_denied(): void
    {
        DB::table('school_management_assignments')->insert([
            ['school_id' => 10, 'user_id' => 30, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 11, 'user_id' => 30, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 10, 'user_id' => 32, 'role' => 'director', 'ends_at' => now()],
            ['school_id' => 10, 'user_id' => 33, 'role' => 'deputy_director', 'ends_at' => null],
        ]);
        $this->assertSame(403, $this->context(30, 'teacher')->getStatusCode());
        $this->assertSame(403, $this->context(32, 'teacher')->getStatusCode());
        $this->assertSame(403, $this->context(33, 'teacher')->getStatusCode());
    }

    public function test_inactive_school_or_institution_is_denied(): void
    {
        $this->assertSame(4, $this->context(21)->getData(true)['school']['organization_id']);
        DB::table('organizations')->where('id', 4)->update(['is_active' => false]);
        $this->assertSame(403, $this->context(21)->getStatusCode());
        DB::table('schools')->where('id', 10)->update(['is_active' => false]);
        $this->assertSame(403, $this->context(20)->getStatusCode());
    }
    public function test_school_context_rejects_multiple_active_school_bindings(): void
    {
        DB::table('school_accounts')->insert(['school_id' => 11, 'user_id' => 20]);
        $this->assertSame(403, $this->context(20)->getStatusCode());
    }

    public function test_requested_school_id_does_not_override_authenticated_school(): void
    {
        // context() deliberately requests foreign school_id=999.
        $data = $this->context(21)->getData(true);
        $this->assertSame(11, $data['school']['id']);
        $this->assertSame('Affiliated', $data['school']['name']);
    }

    public function test_duplicated_binding_does_not_grant_ambiguous_access(): void
    {
        DB::table('school_accounts')->insert(['school_id' => 10, 'user_id' => 20]);
        $this->assertSame(403, $this->context(20)->getStatusCode());
    }

}
