<?php

namespace Tests\Feature;

use App\Http\Middleware\ApiAbuseProtection;
use Illuminate\Http\Request;
use Tests\TestCase;

class ApiAbuseProtectionTest extends TestCase
{
    public function test_write_requests_are_throttled_with_retry_after(): void
    {
        $middleware = app(ApiAbuseProtection::class);
        $ip = '198.51.100.23';

        for ($attempt = 1; $attempt <= 60; $attempt++) {
            $request = Request::create('/api/security-test', 'POST', [], [], [], [
                'REMOTE_ADDR' => $ip,
            ]);

            $response = $middleware->handle($request, fn () => response()->json(['ok' => true]));
            $this->assertSame(200, $response->getStatusCode());
        }

        $blockedRequest = Request::create('/api/security-test', 'POST', [], [], [], [
            'REMOTE_ADDR' => $ip,
        ]);
        $blocked = $middleware->handle($blockedRequest, fn () => response()->json(['ok' => true]));

        $this->assertSame(429, $blocked->getStatusCode());
        $this->assertNotNull($blocked->headers->get('Retry-After'));
        $this->assertSame('0', $blocked->headers->get('X-RateLimit-Remaining'));
    }
}
