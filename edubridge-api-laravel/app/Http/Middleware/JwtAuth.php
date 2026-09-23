<?php

namespace App\Http\Middleware;

use Closure;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;

class JwtAuth
{
    public function handle(Request $request, Closure $next)
    {
        // Laravel only returns a token for a proper "Authorization: Bearer <token>" header.
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json(['error' => 'التوكن مفقود'], 401);
        }

        try {
            $secret = config('services.jwt.secret') ?: env('JWT_SECRET') ?: getenv('JWT_SECRET') ?: ($_ENV['JWT_SECRET'] ?? null);
            $secret = is_string($secret) ? trim($secret) : null;

            if (!$secret) {
                return response()->json(['error' => 'إعداد المصادقة على السيرفر غير مكتمل'], 500);
            }

            $decoded = JWT::decode($token, new Key($secret, 'HS256'));

            $userId = $decoded->id ?? null;
            $role = $decoded->role ?? null;
            if ((!is_int($userId) && !ctype_digit((string) $userId))
                || (int) $userId <= 0
                || !is_string($role)
                || trim($role) === '') {
                return response()->json(['error' => 'توكن غير صالح'], 401);
            }

            // نمرر حمولة التوكن للمسارات التالية — { id, role }
            $request->attributes->set('jwt_user', $decoded);
        } catch (\Throwable $e) {
            return response()->json(['error' => 'توكن غير صالح'], 401);
        }

        return $next($request);
    }
}
