<?php

namespace App\Http\Middleware;

// ميدل وير للتحقق من التوكن — يحمي المسارات المحمية
use Closure;
use Exception;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;

class JwtAuth
{
    public function handle(Request $request, Closure $next)
    {
        $header = $request->header('Authorization');
        // الشكل المتوقع: "Bearer <token>"
        $token = $header ? (explode(' ', $header)[1] ?? null) : null;

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
            // نمرر حمولة التوكن للمسارات التالية — { id, role }
            $request->attributes->set('jwt_user', $decoded);
        } catch (\Throwable $e) {
            return response()->json(['error' => 'توكن غير صالح'], 403);
        }

        return $next($request);
    }
}
