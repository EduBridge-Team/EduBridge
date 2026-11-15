<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionInternalTeacherController;
use App\Support\InstitutionInternalSession;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionInternalTeacherTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug'); $t->string('internal_domain')->nullable()->unique();
            $t->boolean('is_active')->default(true); $t->timestamps();
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->string('internal_domain')->nullable()->unique();
            $t->timestamp('internal_domain_confirmed_at')->nullable();
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('role'); $t->string('password_hash'); $t->string('password')->nullable();
            $t->timestamp('email_verified_at')->nullable();
            $t->string('verification_status')->nullable();
            $t->unsignedInteger('session_version')->default(0); $t->timestamps();
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->boolean('is_active')->default(true); $t->timestamps();
        });
        Schema::create('institution_internal_identities', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id')->unique();
            $t->string('username', 64); $t->boolean('is_active')->default(true);
            $t->boolean('must_change_password')->default(true); $t->timestamps();
            $t->unique(['organization_id', 'username']);
        });
        Schema::create('institution_internal_account_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('actor_id'); $t->unsignedBigInteger('subject_id');
            $t->string('action'); $t->timestamp('created_at');
        });
        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia', 'is_active' => true],
            ['id' => 2, 'slug' => 'other', 'is_active' => true],
        ]);
        DB::table('users')->insert([
            'id' => 10, 'name' => 'Administrator', 'email' => 'admin@example.com',
            'role' => 'institution', 'password_hash' => password_hash('long-password', PASSWORD_BCRYPT),
            'email_verified_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['institution_internal_account_events', 'institution_internal_identities',
            'organization_user', 'users', 'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function invoke(string $method, array $data = [], int $organization = 1, int $identity = 0)
    {
        $request = Request::create('/api/institutions/jabalia/internal-teachers', 'POST', $data);
        $org = DB::table('organizations')->find($organization);
        $request->attributes->set('organization', $org);
        $request->attributes->set('jwt_user', (object) ['id' => 10, 'role' => 'institution']);
        $controller = app(InstitutionInternalTeacherController::class);
        return $method === 'update' || $method === 'resetPassword'
            ? $controller->$method($request, (string) $org->slug, $identity)
            : $controller->$method($request, (string) $org->slug);
    }

    public function test_account_provisions_verified_membership_and_unique_namespace(): void
    {
        $response = $this->invoke('store', ['name' => 'Teacher One', 'username' => 'teacher01']);
        $this->assertSame(201, $response->status());
        $data = $response->getData(true);
        $this->assertSame('teacher01@jabalia.edubridge', $data['accounts'][0]['login_identifier']);
        $this->assertNotEmpty($data['accounts'][0]['temporary_password']);
        $this->assertSame('jabalia.edubridge', DB::table('organizations')->where('id', 1)->value('internal_domain'));
        $userId = $data['accounts'][0]['user_id'];
        $this->assertTrue(password_verify($data['accounts'][0]['temporary_password'],
            DB::table('users')->where('id', $userId)->value('password_hash')));
        $this->assertTrue(InstitutionInternalSession::active($userId));
        $this->assertSame($userId, InstitutionInternalSession::resolve('teacher01@jabalia.edubridge')->id);
        $this->assertSame('teacher', DB::table('organization_user')->where('user_id', $userId)->value('role'));
        $this->assertTrue(InstitutionInternalSession::requiresPasswordChange($userId));
        $this->assertSame(409, $this->invoke('store', [
            'name' => 'Duplicate', 'username' => 'teacher01',
        ])->status());
    }

    public function test_bulk_is_atomic_and_duplicate_rows_are_rejected(): void
    {
        $duplicate = $this->invoke('bulk', ['accounts' => [
            ['name' => 'A', 'username' => 'shared'], ['name' => 'B', 'username' => 'shared'],
        ]]);
        $this->assertSame(422, $duplicate->status());
        $this->assertSame(0, DB::table('institution_internal_identities')->count());
        $result = $this->invoke('bulk', ['accounts' => [
            ['name' => 'A', 'username' => 'alpha'], ['name' => 'B', 'username' => 'beta'],
        ]]);
        $this->assertSame(201, $result->status());
        $accounts = $result->getData(true)['accounts'];
        $this->assertNotSame($accounts[0]['temporary_password'], $accounts[1]['temporary_password']);
        $this->assertSame(2, DB::table('organization_user')->where('organization_id', 1)->count());
    }

    public function test_account_lock_and_password_reset_invalidate_sessions(): void
    {
        $data = $this->invoke('store', ['name' => 'Teacher', 'username' => 'teacher10'])->getData(true);
        $id = $data['accounts'][0]['identity_id'];
        $userId = $data['accounts'][0]['user_id'];
        $this->assertSame(200, $this->invoke('update', ['is_active' => false], 1, $id)->status());
        $this->assertFalse(InstitutionInternalSession::active($userId));
        $this->assertSame(1, DB::table('users')->where('id', $userId)->value('session_version'));
        $this->assertSame(200, $this->invoke('update', ['is_active' => true], 1, $id)->status());
        $this->assertTrue(InstitutionInternalSession::active($userId));
        $reset = $this->invoke('resetPassword', [], 1, $id);
        $this->assertSame(200, $reset->status());
        $this->assertTrue(password_verify($reset->getData(true)['temporary_password'],
            DB::table('users')->where('id', $userId)->value('password_hash')));
        $this->assertTrue(InstitutionInternalSession::requiresPasswordChange($userId));
        $this->assertSame(3, DB::table('users')->where('id', $userId)->value('session_version'));
    }

    public function test_first_login_is_limited_to_password_change_until_updated(): void
    {
        $record = $this->invoke('store', ['name' => 'Teacher', 'username' => 'teacher30'])
            ->getData(true)['accounts'][0];
        config()->set('services.jwt.secret', 'local-test-only-secret');
        $login = \App\Http\Controllers\AuthController::class;
        $loginRequest = Request::create('/api/auth/login', 'POST', [
            'email' => $record['login_identifier'],
            'password' => $record['temporary_password'],
        ]);
        $auth = app($login)->login($loginRequest);
        $this->assertSame(200, $auth->status(), $auth->getContent());
        $this->assertTrue($auth->getData(true)['user']['must_change_password']);
        $token = $auth->getData(true)['token'];
        $middleware = app(\App\Http\Middleware\JwtAuth::class);
        $protected = Request::create('/api/lessons', 'GET');
        $protected->headers->set('Authorization', 'Bearer '.$token);
        $denied = $middleware->handle($protected, fn () => response()->json(['allowed' => true]));
        $this->assertSame(403, $denied->status());
        $allowed = Request::create('/api/me/password', 'PUT');
        $allowed->headers->set('Authorization', 'Bearer '.$token);
        $accepted = $middleware->handle($allowed, fn () => response()->json(['allowed' => true]));
        $this->assertSame(200, $accepted->status());
        $allowed->attributes->set('jwt_user', DB::table('users')->find($record['user_id']));
        $allowed->merge(['current_password' => $record['temporary_password'],
            'new_password' => 'ReplacementPassword123!']);
        $changed = app(\App\Http\Controllers\AccountController::class)->changePassword($allowed);
        $this->assertSame(200, $changed->status());
        $this->assertFalse(InstitutionInternalSession::requiresPasswordChange($record['user_id']));
        $this->assertTrue(password_verify('ReplacementPassword123!',
            DB::table('users')->where('id', $record['user_id'])->value('password_hash')));
        $protected->headers->set('Authorization', 'Bearer '.$changed->getData(true)['token']);
        $this->assertSame(200, $middleware->handle($protected,
            fn () => response()->json(['allowed' => true]))->status());
    }

    public function test_school_namespace_collision_and_tenant_scoping(): void
    {
        DB::table('schools')->insert([
            'internal_domain' => 'jabalia.edubridge',
            'internal_domain_confirmed_at' => now(),
        ]);
        $this->assertSame(409, $this->invoke('store', [
            'name' => 'Teacher', 'username' => 'teacher01',
        ])->status());
        DB::table('schools')->delete();
        $row = $this->invoke('store', ['name' => 'Teacher', 'username' => 'teacher01'])
            ->getData(true)['accounts'][0];
        $this->assertSame(404, $this->invoke('update', ['is_active' => false],
            2, $row['identity_id'])->status());
        $this->assertTrue(InstitutionInternalSession::active($row['user_id']));
    }
}
