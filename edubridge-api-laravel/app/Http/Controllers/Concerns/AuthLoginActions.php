<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait AuthLoginActions
{
    public function login(Request $request)
    {
        $email = $request->input('email');
        $password = $request->input('password');

        if (!$email || !$password) {
            return response()->json(['error' => 'الإيميل والباسورد مطلوبان'], 400);
        }

        try {
            $passwordColumn = $this->getPasswordColumn();
            if (!$passwordColumn) {
                return response()->json([
                    'error' => 'بنية جدول المستخدمين غير مكتملة على السيرفر',
                    'code' => 'AUTH_PASSWORD_COLUMN_MISSING',
                ], 500);
            }

            $user = DB::table('users')->where('email', $email)->first();
            $storedHash = $user?->{$passwordColumn} ?? null;

            if (
                !$user
                || !is_string($storedHash)
                || $storedHash === ''
                || !password_verify($password, $storedHash)
            ) {
                return response()->json(['error' => 'بيانات الدخول غير صحيحة'], 401);
            }

            if (!isset($user->role) || !is_string($user->role) || trim($user->role) === '') {
                return response()->json([
                    'error' => 'بيانات الدور للحساب غير مكتملة على السيرفر',
                    'code' => 'AUTH_ROLE_MISSING',
                ], 500);
            }

            try {
                $token = $this->issueToken($user);
            } catch (\RuntimeException $e) {
                report($e);

                if ($e->getMessage() === 'JWT_SECRET_MISSING') {
                    return response()->json([
                        'error' => 'إعداد المصادقة على السيرفر غير مكتمل',
                        'code' => 'AUTH_JWT_SECRET_MISSING',
                    ], 500);
                }

                return response()->json([
                    'error' => 'تعذر إنشاء جلسة الدخول',
                    'code' => 'AUTH_TOKEN_FAILED',
                ], 500);
            }

            return response()->json([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'specialty' => Schema::hasColumn('users', 'specialty')
                        ? ($user->specialty ?? null)
                        : null,
                    'verification_status' => $user->verification_status ?? 'pending',
                ],
            ]);
        } catch (QueryException $e) {
            report($e);

            return response()->json([
                'error' => 'تعذر قراءة بيانات الحساب من قاعدة البيانات',
                'code' => 'AUTH_DB_ERROR',
            ], 500);
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'error' => 'تعذر إكمال تسجيل الدخول على السيرفر',
                'code' => 'AUTH_SERVER_ERROR',
            ], 500);
        }
    }
}
