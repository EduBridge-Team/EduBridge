<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cookie;

final class WebSessionCookie
{
    public const NAME = 'edubridge_session';

    private const MINUTES = 7 * 24 * 60;

    public static function attach(JsonResponse $response, string $token): JsonResponse
    {
        return $response->withCookie(Cookie::make(
            self::NAME,
            $token,
            self::MINUTES,
            '/api',
            null,
            true,
            true,
            false,
            'Lax'
        ));
    }

    public static function forget(JsonResponse $response): JsonResponse
    {
        return $response->withCookie(Cookie::forget(self::NAME, '/api'));
    }
}
