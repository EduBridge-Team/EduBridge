<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Cache\RateLimiter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiAbuseProtection
{
    public function __construct(private readonly RateLimiter $limiter)
    {
    }

    public function handle(Request $request, Closure $next): Response
    {
        $isWrite = ! in_array(strtoupper($request->method()), ['GET', 'HEAD', 'OPTIONS'], true);
        $user = $request->attributes->get('jwt_user');
        $actor = $user ? 'user:' . $user->id : 'ip:' . $request->ip();
        $ip = 'ip:' . $request->ip();

        $actorLimit = $isWrite ? 60 : 240;
        $ipLimit = $isWrite ? 120 : 360;
        $bucket = $isWrite ? 'write' : 'read';

        $keys = [
            ["api:$bucket:actor:$actor", $actorLimit],
            ["api:$bucket:ip:$ip", $ipLimit],
        ];

        foreach ($keys as [$key, $limit]) {
            if ($this->limiter->tooManyAttempts($key, $limit)) {
                return $this->blocked($key, $limit);
            }
        }

        foreach ($keys as [$key]) {
            $this->limiter->hit($key, 60);
        }

        /** @var Response $response */
        $response = $next($request);
        $response->headers->set('X-RateLimit-Policy', $isWrite ? 'write-60-per-minute' : 'read-240-per-minute');

        return $response;
    }

    private function blocked(string $key, int $limit): JsonResponse
    {
        $retryAfter = max(1, $this->limiter->availableIn($key));

        return response()->json([
            'message' => 'عدد الطلبات كبير جدًا. حاول مرة أخرى بعد قليل.',
            'retry_after' => $retryAfter,
        ], 429, [
            'Retry-After' => (string) $retryAfter,
            'X-RateLimit-Limit' => (string) $limit,
            'X-RateLimit-Remaining' => '0',
        ]);
    }
}
