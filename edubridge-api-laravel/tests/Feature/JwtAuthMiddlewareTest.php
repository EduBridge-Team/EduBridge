<?php

namespace Tests\Feature;

use App\Http\Middleware\JwtAuth;
use Firebase\JWT\JWT;
use Illuminate\Http\Request;
use Tests\TestCase;
use App\Support\AuthCredentials;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;

class JwtAuthMiddlewareTest extends TestCase
{
    private const SECRET = 'jwt-middleware-test-secret-32-bytes-minimum-value';

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.jwt.secret' => self::SECRET]);
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('role');
            $table->string('password_hash');
        });
        DB::table('users')->insert(['id' => 1, 'role' => 'parent', 'password_hash' => 'stored-credential']);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_rejects_non_bearer_authorization_header(): void
    {
        $request = Request::create('/api/me', 'GET');
        $request->headers->set('Authorization', 'Basic abc123');

        $response = (new JwtAuth())->handle(
            $request,
            fn () => response()->json(['ok' => true])
        );

        $this->assertSame(401, $response->getStatusCode());
    }

    public function test_rejects_token_missing_required_claims(): void
    {
        $token = JWT::encode(
            ['id' => 1, 'iat' => time(), 'exp' => time() + 300],
            self::SECRET,
            'HS256'
        );

        $request = Request::create('/api/me', 'GET');
        $request->headers->set('Authorization', 'Bearer ' . $token);

        $response = (new JwtAuth())->handle(
            $request,
            fn () => response()->json(['ok' => true])
        );

        $this->assertSame(401, $response->getStatusCode());
    }

    public function test_accepts_valid_bearer_token_with_required_claims(): void
    {
        $token = JWT::encode(
            ['id' => 1, 'role' => 'parent', 'iat' => time(), 'exp' => time() + 300,
                'credential_stamp' => AuthCredentials::stamp(DB::table('users')->find(1), self::SECRET)],
            self::SECRET,
            'HS256'
        );

        $request = Request::create('/api/me', 'GET');
        $request->headers->set('Authorization', 'Bearer ' . $token);

        $response = (new JwtAuth())->handle(
            $request,
            fn () => response()->json(['ok' => true])
        );

        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame(1, $request->attributes->get('jwt_user')->id);
        $this->assertSame('parent', $request->attributes->get('jwt_user')->role);
    }

    public function test_deleted_accounts_changed_roles_and_changed_passwords_reject_old_tokens(): void
    {
        $claims = ['id' => 1, 'role' => 'parent', 'iat' => time(), 'exp' => time() + 300,
            'credential_stamp' => AuthCredentials::stamp(DB::table('users')->find(1), self::SECRET)];
        $request = Request::create('/api/me', 'GET');
        $request->headers->set('Authorization', 'Bearer ' . JWT::encode($claims, self::SECRET, 'HS256'));
        $check = fn () => (new JwtAuth())->handle($request, fn () => response()->json(['ok' => true]))->getStatusCode();
        DB::table('users')->where('id', 1)->update(['role' => 'admin']);
        $this->assertSame(401, $check());
        DB::table('users')->where('id', 1)->update(['role' => 'parent', 'password_hash' => 'new-credential']);
        $this->assertSame(401, $check());
        DB::table('users')->where('id', 1)->delete();
        $this->assertSame(401, $check());
    }

    public function test_legacy_tokens_without_credential_stamp_require_sign_in(): void
    {
        $request = Request::create('/api/me', 'GET');
        $request->headers->set('Authorization', 'Bearer ' . JWT::encode(
            ['id' => 1, 'role' => 'parent', 'exp' => time() + 300], self::SECRET, 'HS256'));
        $response = (new JwtAuth())->handle($request, fn () => response()->json(['ok' => true]));
        $this->assertSame(401, $response->getStatusCode());
    }
}
