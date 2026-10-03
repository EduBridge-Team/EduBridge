<?php

namespace Tests\Feature;

use App\Http\Middleware\WebSessionBridge;
use App\Support\WebSessionCookie;
use Illuminate\Http\Request;
use Tests\TestCase;

class WebSessionBridgeTest extends TestCase
{
    public function test_cookie_is_bridged_to_bearer_authorization_for_existing_auth_middleware(): void
    {
        $request = Request::create('/api/me', 'GET', [], [WebSessionCookie::NAME => 'cookie-jwt']);

        $response = (new WebSessionBridge())->handle($request, function (Request $request) {
            $this->assertSame('Bearer cookie-jwt', $request->header('Authorization'));
            return response()->json(['ok' => true]);
        });

        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_bearer_authorization_takes_precedence_over_cookie(): void
    {
        $request = Request::create('/api/me', 'GET', [], [WebSessionCookie::NAME => 'cookie-jwt']);
        $request->headers->set('Authorization', 'Bearer mobile-jwt');

        (new WebSessionBridge())->handle($request, function (Request $request) {
            $this->assertSame('Bearer mobile-jwt', $request->header('Authorization'));
            return response()->json(['ok' => true]);
        });
    }

    public function test_successful_login_response_sets_secure_httponly_samesite_cookie(): void
    {
        $request = Request::create('/api/auth/login', 'POST');
        $response = (new WebSessionBridge())->handle(
            $request,
            fn () => response()->json(['token' => 'signed-jwt', 'user' => ['id' => 1]])
        );

        $cookies = $response->headers->getCookies();
        $this->assertCount(1, $cookies);
        $cookie = $cookies[0];
        $this->assertSame(WebSessionCookie::NAME, $cookie->getName());
        $this->assertSame('signed-jwt', $cookie->getValue());
        $this->assertSame('/api', $cookie->getPath());
        $this->assertTrue($cookie->isSecure());
        $this->assertTrue($cookie->isHttpOnly());
        $this->assertSame('lax', strtolower((string) $cookie->getSameSite()));
    }

    public function test_first_party_web_login_hides_token_from_json_but_keeps_cookie(): void
    {
        $request = Request::create('/api/auth/login', 'POST');
        $request->headers->set('X-EduBridge-Client', 'web');

        $response = (new WebSessionBridge())->handle(
            $request,
            fn () => response()->json(['token' => 'signed-jwt', 'user' => ['id' => 1]])
        );

        $payload = $response->getData(true);
        $this->assertArrayNotHasKey('token', $payload);
        $this->assertSame(['id' => 1], $payload['user']);
        $this->assertCount(1, $response->headers->getCookies());
        $this->assertSame('signed-jwt', $response->headers->getCookies()[0]->getValue());
    }

    public function test_mobile_login_keeps_bearer_token_in_json(): void
    {
        $request = Request::create('/api/auth/login', 'POST');
        $response = (new WebSessionBridge())->handle(
            $request,
            fn () => response()->json(['token' => 'mobile-jwt', 'user' => ['id' => 1]])
        );

        $this->assertSame('mobile-jwt', $response->getData(true)['token']);
    }

    public function test_logout_expires_web_session_cookie_with_security_attributes(): void
    {
        $request = Request::create('/api/auth/logout', 'POST');
        $response = (new WebSessionBridge())->handle(
            $request,
            fn () => response()->json(['message' => 'ok'])
        );

        $cookies = $response->headers->getCookies();
        $this->assertCount(1, $cookies);
        $cookie = $cookies[0];
        $this->assertSame(WebSessionCookie::NAME, $cookie->getName());
        $this->assertTrue($cookie->getExpiresTime() <= time());
        $this->assertTrue($cookie->isSecure());
        $this->assertTrue($cookie->isHttpOnly());
        $this->assertSame('lax', strtolower((string) $cookie->getSameSite()));
        $this->assertSame('/api', $cookie->getPath());
    }
}
