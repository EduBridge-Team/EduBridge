<?php

namespace App\Http\Middleware;

use Closure;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\AuthCredentials;

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

            $account = DB::table('users')->where('id', (int) $userId)->first();
            if (!$account) {
                return response()->json(['error' => 'انتهت جلسة الدخول. سجّل الدخول مجدداً.', 'code' => 'SESSION_INVALID'], 401);
            }

            $tokenSessionVersion = (int) ($decoded->session_version ?? 0);
            $accountSessionVersion = (int) ($account->session_version ?? 0);
            if ($account->role !== $role
                || $tokenSessionVersion !== $accountSessionVersion
                || !isset($decoded->exp, $decoded->credential_stamp)
                || !is_string($decoded->credential_stamp)
                || !hash_equals(AuthCredentials::stamp($account, $secret), $decoded->credential_stamp)) {
                return response()->json(['error' => 'انتهت جلسة الدخول. سجّل الدخول مجدداً.', 'code' => 'SESSION_INVALID'], 401);
            }

            if (str_ends_with(strtolower((string) ($account->email ?? '')), '.edubridge')) {
                if (!\App\Support\SchoolInternalSession::active((int) $account->id)) {
                    return response()->json(['error' => 'School identity unavailable', 'code' => 'SESSION_INVALID'], 401);
                }
            }

            if ($account->role === 'school') {
                // Check every request, not only login. A previously issued JWT must
                // stop working as soon as its school or institution is disabled.
                $activeSchools = DB::table('school_accounts as sa')
                    ->join('schools as s', 's.id', '=', 'sa.school_id')
                    ->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
                    ->where('sa.user_id', $account->id)
                    ->where('s.is_active', true)
                    ->where(function ($query) {
                        $query->whereNull('s.organization_id')->orWhere('o.is_active', true);
                    })
                    ->limit(2)
                    ->count();

                if ($activeSchools !== 1) {
                    return response()->json([
                        'error' => 'انتهت صلاحية حساب المدرسة',
                        'code' => 'SESSION_INVALID',
                    ], 401);
                }
            }

            // The current database account is authoritative for every policy.
            $request->attributes->set('jwt_user', $account);
        } catch (\Throwable $e) {
            return response()->json(['error' => 'توكن غير صالح'], 401);
        }

        return $next($request);
    }
}
