<?php

namespace Tests\Feature;

use App\Support\TrustedProxyConfiguration;
use Illuminate\Http\Middleware\TrustProxies;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Tests\TestCase;

class TrustedProxyHeadersTest extends TestCase
{
    protected function tearDown(): void
    {
        TrustProxies::flushState();
        parent::tearDown();
    }

    private function proxyContext(Request $request): array
    {
        TrustProxies::at(TrustedProxyConfiguration::PROXIES);
        TrustProxies::withHeaders(TrustedProxyConfiguration::HEADERS);

        $response = (new TrustProxies())->handle(
            $request,
            static fn (Request $trustedRequest) => new Response(json_encode([
                'ip' => $trustedRequest->ip(),
                'secure' => $trustedRequest->isSecure(),
                'host' => $trustedRequest->getHost(),
            ], JSON_THROW_ON_ERROR), 200, ['Content-Type' => 'application/json'])
        );

        return json_decode((string) $response->getContent(), true, 512, JSON_THROW_ON_ERROR);
    }

    public function test_internal_caddy_proxy_headers_are_trusted(): void
    {
        $request = Request::create('http://origin.invalid/_test/proxy-context', 'GET', [], [], [], [
            'REMOTE_ADDR' => '172.18.0.1',
            'SERVER_PORT' => '80',
            'HTTP_HOST' => 'origin.invalid',
            'HTTP_X_FORWARDED_FOR' => '203.0.113.27',
            'HTTP_X_FORWARDED_PROTO' => 'https',
            'HTTP_X_FORWARDED_HOST' => 'api.edubridge.win',
            'HTTP_X_FORWARDED_PORT' => '443',
        ]);

        $this->assertSame([
            'ip' => '203.0.113.27',
            'secure' => true,
            'host' => 'api.edubridge.win',
        ], $this->proxyContext($request));
    }

    public function test_untrusted_peer_cannot_spoof_forwarded_headers(): void
    {
        $request = Request::create('http://origin.invalid/_test/proxy-context', 'GET', [], [], [], [
            'REMOTE_ADDR' => '198.51.100.44',
            'SERVER_PORT' => '80',
            'HTTP_HOST' => 'origin.invalid',
            'HTTP_X_FORWARDED_FOR' => '203.0.113.99',
            'HTTP_X_FORWARDED_PROTO' => 'https',
            'HTTP_X_FORWARDED_HOST' => 'api.edubridge.win',
            'HTTP_X_FORWARDED_PORT' => '443',
        ]);

        $this->assertSame([
            'ip' => '198.51.100.44',
            'secure' => false,
            'host' => 'origin.invalid',
        ], $this->proxyContext($request));
    }
}
