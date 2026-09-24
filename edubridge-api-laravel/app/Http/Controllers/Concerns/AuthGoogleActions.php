<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

trait AuthGoogleActions
{
    public function google(Request $request)
    {
        $idToken = $request->input('id_token') ?: $request->input('idToken');

        if (!$idToken) {
            return response()->json(['error' => 'الرمز المرسل من Google مطلوب'], 400);
        }

        $googleClientId = $this->getGoogleClientId();
        if (!$googleClientId) {
            return response()->json(['error' => 'لم يتم تكوين Google OAuth بعد'], 500);
        }

        try {
            $response = Http::get('https://oauth2.googleapis.com/tokeninfo', ['id_token' => $idToken]);

            if (!$response->successful()) {
                return response()->json(['error' => 'رمز Google غير صالح'], 401);
            }

            $payload = $response->json();
            if (($payload['aud'] ?? '') !== $googleClientId) {
                return response()->json(['error' => 'رمز Google غير صالح'], 401);
            }

            $email = $payload['email'] ?? null;
            $name = $payload['name'] ?? $payload['given_name'] ?? ($email ? explode('@', $email)[0] : 'Google User');
            $emailVerified = $payload['email_verified'] ?? false;

            if (!$email) {
                return response()->json(['error' => 'البريد الإلكتروني من Google غير متوفر'], 401);
            }
            if (!in_array($emailVerified, [true, 1, '1', 'true'], true)) {
                return response()->json(['error' => 'البريد الإلكتروني في حساب Google غير موثّق'], 401);
            }

            $user = DB::table('users')->where('email', $email)->first();

            if (!$user) {
                $passwordHash = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT, ['cost' => 10]);
                $id = DB::table('users')->insertGetId([
                    'name' => $name,
                    'email' => $email,
                    'password_hash' => $passwordHash,
                    'role' => 'parent',
                ]);

                $user = DB::table('users')
                    ->select('id', 'name', 'email', 'role', 'phone', 'created_at')
                    ->find($id);
            }

            try {
                $token = $this->issueToken($user);
            } catch (\RuntimeException $e) {
                report($e);
                return response()->json([
                    'error' => $e->getMessage() === 'JWT_SECRET_MISSING'
                        ? 'إعداد المصادقة على السيرفر غير مكتمل'
                        : 'تعذر إنشاء جلسة الدخول',
                    'code' => $e->getMessage() === 'JWT_SECRET_MISSING'
                        ? 'AUTH_JWT_SECRET_MISSING'
                        : 'AUTH_TOKEN_FAILED',
                ], 500);
            }

            return response()->json([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'verification_status' => $user->verification_status ?? 'pending',
                ],
            ]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
