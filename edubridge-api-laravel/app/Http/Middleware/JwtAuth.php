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
            $decoded = JWT::decode($token, new Key(env('JWT_SECRET'), 'HS256'));
            // نمرر حمولة التوكن للمسارات التالية — { id, role }
            $request->attributes->set('jwt_user', $decoded);
        } catch (Exception $e) {
            return response()->json(['error' => 'توكن غير صالح'], 403);
        }

        return $next($request);
    }
}
