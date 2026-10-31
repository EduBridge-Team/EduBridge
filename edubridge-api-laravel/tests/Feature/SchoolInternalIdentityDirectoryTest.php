<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolInternalIdentityDirectoryController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolInternalIdentityDirectoryTest extends TestCase
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
            $t->string('internal_domain')->nullable();
            $t->timestamp('internal_domain_confirmed_at')->nullable();
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('role');
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
            $t->string('role');
            $t->timestamp('ends_at')->nullable();
        });
        Schema::create('school_internal_identities', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
            $t->string('username');
        });
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => 1, 'is_active' => true,
                'internal_domain' => 'alpha.edubridge', 'internal_domain_confirmed_at' => now()],
            ['id' => 11, 'organization_id' => null, 'is_active' => true,
                'internal_domain' => 'beta.edubridge', 'internal_domain_confirmed_at' => now()],
        ]);
        DB::table('users')->insert([
            ['id' => 20, 'name' => 'Director', 'role' => 'teacher'],
            ['id' => 21, 'name' => 'Teacher A', 'role' => 'teacher'],
            ['id' => 22, 'name' => 'Student A', 'role' => 'student'],
            ['id' => 23, 'name' => 'Other School', 'role' => 'teacher'],
        ]);
        DB::table('school_management_assignments')->insert([
            ['school_id' => 10, 'user_id' => 20, 'role' => 'director', 'ends_at' => null],
        ]);
        DB::table('school_internal_identities')->insert([
            ['id' => 1, 'school_id' => 10, 'user_id' => 21, 'username' => 'teacher1'],
            ['id' => 2, 'school_id' => 10, 'user_id' => 22, 'username' => 'student1'],
            ['id' => 3, 'school_id' => 11, 'user_id' => 23, 'username' => 'teacher1'],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('school_internal_identities');
        Schema::dropIfExists('school_management_assignments');
        Schema::dropIfExists('users');
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    private function directory(int $actor, array $query = []): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/internal-identities', 'GET', $query);
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => 'teacher']);
        return app(SchoolInternalIdentityDirectoryController::class)->index($request);
    }

    public function test_director_only_sees_own_school_identities(): void
    {
        $response = $this->directory(20);
        $this->assertSame(200, $response->getStatusCode());
        $data = $response->getData(true);
        $this->assertSame(10, $data['school_id']);
        $this->assertCount(2, $data['identities']);
        $this->assertSame(['teacher1', 'student1'], array_column($data['identities'], 'username'));
        $this->assertArrayNotHasKey('email', $data['identities'][0]);
        $this->assertSame(403, $this->directory(21)->getStatusCode());
    }

    public function test_cursor_and_role_filters_are_validated(): void
    {
        $first = $this->directory(20, ['limit' => 1])->getData(true);
        $this->assertTrue($first['has_more']);
        $this->assertSame(1, $first['next_after_id']);
        $second = $this->directory(20, ['after_id' => $first['next_after_id'], 'limit' => 1])->getData(true);
        $this->assertSame('student1', $second['identities'][0]['username']);
        $this->assertFalse($second['has_more']);
        $this->assertCount(1, $this->directory(20, ['role' => 'teacher'])->getData(true)['identities']);
        $this->assertSame(422, $this->directory(20, ['limit' => 101])->getStatusCode());
        $this->assertSame(422, $this->directory(20, ['role' => 'admin'])->getStatusCode());
    }

    public function test_inactive_or_unconfirmed_school_and_ambiguous_director_are_denied(): void
    {
        DB::table('schools')->where('id', 10)->update(['internal_domain_confirmed_at' => null]);
        $this->assertSame(409, $this->directory(20)->getStatusCode());
        DB::table('schools')->where('id', 10)->update(['internal_domain_confirmed_at' => now()]);
        DB::table('organizations')->where('id', 1)->update(['is_active' => false]);
        $this->assertSame(403, $this->directory(20)->getStatusCode());
        DB::table('organizations')->where('id', 1)->update(['is_active' => true]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 11, 'user_id' => 20, 'role' => 'director', 'ends_at' => null,
        ]);
        $this->assertSame(403, $this->directory(20)->getStatusCode());
    }
}
