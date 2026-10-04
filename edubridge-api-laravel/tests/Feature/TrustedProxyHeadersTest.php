<?php

namespace Tests\Feature;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class TrustedProxyHeadersTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Route::get('/_test/proxy-context', static fn (Request $request) => response()->json([
            'ip' => $request->ip(),
            'secure' => $request->isSecure(),
            'host' => $request->getHost(),
        ]));
    }

    public function test_internal_caddy_proxy_headers_are_trusted(): void
    {
        $response = $this
            ->withServerVariables(['REMOTE_ADDR' => '172.18.0.1'])
            ->withHeaders([
                'X-Forwarded-For' => '203.0.113.27',
                'X-Forwarded-Proto' => 'https',
                'X-Forwarded-Host' => 'api.edubridge.win',
                'X-Forwarded-Port' => '443',
            ])
            ->get('/_test/proxy-context');

        $response->assertOk()->assertJson([
            'ip' => '203.0.113.27',
            'secure' => true,
            'host' => 'api.edubridge.win',
        ]);
    }

    public function test_untrusted_peer_cannot_spoof_forwarded_headers(): void
    {
        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '198.51.100.44',
                'HTTPS' => 'off',
                'SERVER_PORT' => '80',
                'HTTP_HOST' => 'origin.invalid',
            ])
            ->withHeaders([
                'X-Forwarded-For' => '203.0.113.99',
                'X-Forwarded-Proto' => 'https',
                'X-Forwarded-Host' => 'api.edubridge.win',
                'X-Forwarded-Port' => '443',
            ])
            ->get('/_test/proxy-context');

        $response->assertOk()->assertJson([
            'ip' => '198.51.100.44',
            'secure' => false,
            'host' => 'origin.invalid',
        ]);
    }
}
