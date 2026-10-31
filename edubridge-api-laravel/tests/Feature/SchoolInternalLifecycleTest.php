<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolInternalLifecycleController;
use App\Support\SchoolInternalSession;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SchoolInternalLifecycleTest extends \Tests\TestCase
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
            $t->string('email')->unique();
            $t->string('role');
            $t->string('password_hash');
            $t->string('password')->nullable();
            $t->timestamp('email_verified_at')->nullable();
            $t->string('verification_status')->nullable();
            $t->timestamps();
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
            $t->unsignedBigInteger('user_id')->unique();
            $t->string('username');
            $t->timestamps();
            $t->unique(['school_id', 'username']);
        });
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => 1, 'is_active' => true,
                'internal_domain' => 'alpha.edubridge', 'internal_domain_confirmed_at' => now()],
            ['id' => 11, 'organization_id' => null, 'is_active' => true,
                'internal_domain' => 'beta.edubridge', 'internal_domain_confirmed_at' => now()],
        ]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 10, 'user_id' => 20, 'role' => 'director', 'ends_at' => null,
        ]);
        Schema::table('school_internal_identities', fn (Blueprint $t) => $t->boolean('is_active')->default(true));
        Schema::table('users', fn (Blueprint $t) => $t->integer('session_version')->default(0));
        Schema::create('school_administration_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('actor_id');
            $t->string('action'); $t->unsignedBigInteger('subject_id')->nullable(); $t->timestamp('created_at');
        });
        DB::table('users')->insert(['id' => 90, 'name' => 'Internal', 'email' => 'teacher01@alpha.edubridge',
            'role' => 'teacher', 'password_hash' => password_hash('StrongPassword123', PASSWORD_BCRYPT)]);
        DB::table('school_internal_identities')->insert(['id' => 5, 'school_id' => 10, 'user_id' => 90, 'username' => 'teacher01']);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('school_administration_events');
        Schema::dropIfExists('school_internal_identities');
        Schema::dropIfExists('school_management_assignments');
        Schema::dropIfExists('users');
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    private function updateIdentity(array $data, int $actor = 20): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/internal-identities/5', 'PATCH', $data);
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => 'teacher']);
        return app(SchoolInternalLifecycleController::class)->update($request, 5);
    }

    public function test_deactivation_revokes_access_and_increments_session_version(): void
    {
        $this->assertTrue(SchoolInternalSession::active(90));
        $this->assertSame(200, $this->updateIdentity(['is_active' => false])->getStatusCode());
        $this->assertFalse(SchoolInternalSession::active(90));
        $this->assertSame(1, (int) DB::table('users')->where('id', 90)->value('session_version'));
        $this->assertSame(200, $this->updateIdentity(['is_active' => true])->getStatusCode());
        $this->assertTrue(SchoolInternalSession::active(90));
        $this->assertSame(2, (int) DB::table('users')->where('id', 90)->value('session_version'));
    }

    public function test_password_reset_hashes_credentials_and_never_returns_password(): void
    {
        $response = $this->updateIdentity(['password' => 'NewStrongPassword456']);
        $this->assertSame(200, $response->getStatusCode());
        $user = DB::table('users')->where('id', 90)->first();
        $this->assertTrue(password_verify('NewStrongPassword456', $user->password_hash));
        $this->assertSame($user->password, $user->password_hash);
        $this->assertStringNotContainsString('NewStrongPassword456', $response->getContent());
        $this->assertSame(1, DB::table('school_administration_events')->count());
    }

    public function test_non_director_cannot_modify_internal_account(): void
    {
        $this->assertSame(403, $this->updateIdentity(['is_active' => false], 90)->getStatusCode());
        $this->assertTrue(SchoolInternalSession::active(90));
    }

    public function test_foreign_school_identity_is_inaccessible(): void
    {
        DB::table('school_internal_identities')->where('id', 5)->update(['school_id' => 11]);
        $this->assertSame(404, $this->updateIdentity(['is_active' => false])->getStatusCode());
    }
}
