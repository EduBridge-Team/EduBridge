<?php

namespace Tests\Feature;

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
        $response->assertHeader('Cross-Origin-Opener-Policy', 'same-origin-allow-popups');
        $response->assertHeader(
            'Permissions-Policy',
            'camera=(), microphone=(self), geolocation=(), payment=(), usb=(), browsing-topics=()'
        );
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
}
