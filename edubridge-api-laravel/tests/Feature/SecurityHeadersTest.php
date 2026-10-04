<?php

namespace Tests\Feature;

use App\Http\Middleware\SecurityHeaders;
use Illuminate\Http\Request;
use Tests\TestCase;

class SecurityHeadersTest extends TestCase
{
    public function test_global_security_headers_are_present(): void
    {
        $response = $this->get('/up');

        $response->assertHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        $response->assertHeader('X-Content-Type-Options', 'nosniff');
        $response->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->assertHeader('X-Frame-Options', 'SAMEORIGIN');
        $response->assertHeader('X-Permitted-Cross-Domain-Policies', 'none');
        $response->assertHeader('Origin-Agent-Cluster', '?1');
        $response->assertHeader('Cross-Origin-Opener-Policy', 'same-origin-allow-popups');
        $response->assertHeader(
            'Permissions-Policy',
            'camera=(), microphone=(self), geolocation=(), payment=(), usb=(), browsing-topics=()'
        );
    }

    public function test_auth_responses_are_not_cacheable(): void
    {
        $response = $this->postJson('/api/auth/login', []);

        $this->assertCacheControlIsPrivateAndNonCacheable($response->headers->get('Cache-Control'));
        $response->assertHeader('Pragma', 'no-cache');
    }

    public function test_private_file_responses_are_not_cacheable_even_when_request_is_rejected(): void
    {
        $response = $this->get('/api/private-files/lesson/1/example.pdf');

        $this->assertCacheControlIsPrivateAndNonCacheable($response->headers->get('Cache-Control'));
        $response->assertHeader('Pragma', 'no-cache');
    }

    public function test_authenticated_api_responses_are_not_cacheable(): void
    {
        $request = Request::create('/api/children', 'GET');
        $middleware = new SecurityHeaders();

        $response = $middleware->handle($request, function (Request $request) {
            $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'parent']);

            return response()->json(['ok' => true]);
        });

        $this->assertCacheControlIsPrivateAndNonCacheable($response->headers->get('Cache-Control'));
        $this->assertSame('no-cache', $response->headers->get('Pragma'));
    }

    public function test_cors_configuration_does_not_allow_arbitrary_methods(): void
    {
        $methods = config('cors.allowed_methods');

        $this->assertNotContains('*', $methods);
        $this->assertSame(
            ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
            $methods
        );
    }

    private function assertCacheControlIsPrivateAndNonCacheable(?string $value): void
    {
        $this->assertNotNull($value);

        foreach (['no-store', 'private', 'max-age=0', 'must-revalidate'] as $directive) {
            $this->assertStringContainsString($directive, $value);
        }
    }
}
