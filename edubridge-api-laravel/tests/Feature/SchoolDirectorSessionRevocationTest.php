<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use App\Http\Middleware\JwtAuth;
use App\Support\AuthCredentials;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolDirectorSessionRevocationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set('services.jwt.secret', 'test-director-session-revocation-secret');

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password_hash');
            $table->string('role');
            $table->unsignedBigInteger('session_version')->default(0);
            $table->timestamp('email_verified_at')->nullable();
        });
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id')->nullable();
            $table->boolean('is_active');
        });
        Schema::create('school_management_assignments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id');
            $table->unsignedBigInteger('user_id');
            $table->string('role');
            $table->timestamp('ends_at')->nullable();
        });
        DB::table('users')->insert([
            ['id' => 10, 'name' => 'Director', 'email' => 'director@example.test',
                'password_hash' => password_hash('StrongDirectorPassword123', PASSWORD_BCRYPT),
                'role' => 'school_director', 'email_verified_at' => now(), 'session_version' => 0],
            ['id' => 20, 'name' => 'Parent', 'email' => 'parent@example.test',
                'password_hash' => password_hash('StrongParentPassword123', PASSWORD_BCRYPT),
                'role' => 'parent', 'email_verified_at' => now(), 'session_version' => 0],
        ]);
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('schools')->insert(['id' => 1, 'organization_id' => 1, 'is_active' => true]);
        DB::table('school_management_assignments')->insert([
            'id' => 1, 'school_id' => 1, 'user_id' => 10, 'role' => 'director', 'ends_at' => null,
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_management_assignments', 'schools', 'organizations', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function login(string $email = 'director@example.test', string $password = 'StrongDirectorPassword123'): \Illuminate\Http\JsonResponse
    {
        return app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => $email, 'password' => $password,
        ]));
    }

    private function authenticated(string $token): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/me', 'GET', [], [], [], [
            'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
        ]);

        return app(JwtAuth::class)->handle(
            $request, fn (Request $request) => response()->json([
                'authenticated_user_id' => (int) $request->attributes->get('jwt_user')->id,
            ])
        );
    }

    public function test_director_login_and_jwt_are_rejected_after_assignment_ends(): void
    {
        $response = $this->login();
        $this->assertSame(200, $response->status());
        $token = $response->getData(true)['token'];
        $this->assertSame(10, $this->authenticated($token)->getData(true)['authenticated_user_id']);

        DB::table('school_management_assignments')->where('id', 1)->update(['ends_at' => now()]);

        $this->assertSame(403, $this->login()->status());
        $revoked = $this->authenticated($token);
        $this->assertSame(401, $revoked->status());
        $this->assertSame('SESSION_INVALID', $revoked->getData(true)['code']);
    }

    public function test_director_is_denied_if_school_or_organization_is_inactive(): void
    {
        $token = AuthCredentials::issue(DB::table('users')->where('id', 10)->first(), config('services.jwt.secret'));

        DB::table('schools')->where('id', 1)->update(['is_active' => false]);
        $this->assertSame(401, $this->authenticated($token)->status());
        $this->assertSame(403, $this->login()->status());

        DB::table('schools')->where('id', 1)->update(['is_active' => true]);
        DB::table('organizations')->where('id', 1)->update(['is_active' => false]);
        $this->assertSame(401, $this->authenticated($token)->status());
        $this->assertSame(403, $this->login()->status());
    }

    public function test_multiple_director_assignments_fail_closed(): void
    {
        DB::table('schools')->insert(['id' => 2, 'organization_id' => 1, 'is_active' => true]);
        DB::table('school_management_assignments')->insert([
            'id' => 2, 'school_id' => 2, 'user_id' => 10, 'role' => 'director', 'ends_at' => null,
        ]);
        $token = AuthCredentials::issue(DB::table('users')->where('id', 10)->first(), config('services.jwt.secret'));
        $this->assertSame(401, $this->authenticated($token)->status());
        $this->assertSame(403, $this->login()->status());
    }

    public function test_independent_director_assignment_remains_supported(): void
    {
        DB::table('schools')->where('id', 1)->update(['organization_id' => null]);
        $response = $this->login();
        $this->assertSame(200, $response->status());
        $this->assertSame(200, $this->authenticated($response->getData(true)['token'])->status());
    }

    public function test_unrelated_parent_login_and_jwt_are_unaffected(): void
    {
        DB::table('school_management_assignments')->where('id', 1)->update(['ends_at' => now()]);
        $response = $this->login('parent@example.test', 'StrongParentPassword123');
        $this->assertSame(200, $response->status());
        $this->assertSame(20, $this->authenticated($response->getData(true)['token'])
            ->getData(true)['authenticated_user_id']);
    }
}
