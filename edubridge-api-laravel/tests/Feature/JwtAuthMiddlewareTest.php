<?php

namespace Tests\Feature;

use App\Http\Middleware\JwtAuth;
use Firebase\JWT\JWT;
use Illuminate\Http\Request;
use Tests\TestCase;

class JwtAuthMiddlewareTest extends TestCase
{
    private const SECRET = 'jwt-middleware-test-secret-32-bytes-minimum-value';

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.jwt.secret' => self::SECRET]);
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
            ['id' => 1, 'role' => 'parent', 'iat' => time(), 'exp' => time() + 300],
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
}
