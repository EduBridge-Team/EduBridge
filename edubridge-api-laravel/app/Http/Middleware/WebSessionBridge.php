<?php

namespace App\Http\Middleware;

use App\Support\WebSessionCookie;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class WebSessionBridge
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->bearerToken()) {
            $cookieToken = $request->cookie(WebSessionCookie::NAME);
            if (is_string($cookieToken) && $cookieToken !== '') {
                $request->headers->set('Authorization', 'Bearer '.$cookieToken);
            }
        }

        /** @var Response $response */
        $response = $next($request);

        if ($response instanceof JsonResponse && $response->isSuccessful()) {
            $isWebClient = strtolower((string) $request->header('X-EduBridge-Client')) === 'web';

            if ($request->is('api/auth/login') || $request->is('api/auth/google') || $request->is('api/me/password')) {
                $payload = $response->getData(true);
                $token = is_array($payload) ? ($payload['token'] ?? null) : null;
                if (is_string($token) && $token !== '') {
                    WebSessionCookie::attach($response, $token);

                    // Browser sessions authenticate only with the HttpOnly cookie.
                    // Keep the token in JSON for Flutter/mobile compatibility, but
                    // never expose it to the first-party web client JavaScript.
                    if ($isWebClient && is_array($payload)) {
                        unset($payload['token']);
                        $response->setData($payload);
                    }
                }
            }

            if ($request->is('api/auth/logout')) {
                WebSessionCookie::forget($response);
            }
        }

        return $response;
    }
}
