<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait AuthRegisterActions
{
    public function register(Request $request)
    {
        $name = trim((string) $request->input('name'));
        $email = trim((string) $request->input('email'));
        $password = (string) $request->input('password');
        $role = $request->input('role');
        $phone = $request->input('phone');
        $specialty = $request->input('specialty');

        if ($name === '' || $email === '' || $password === '' || !$role) {
            return response()->json(['error' => 'الاسم والإيميل والباسورد والدور مطلوبة'], 400);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return response()->json(['error' => 'البريد الإلكتروني غير صالح'], 422);
        }
        if (mb_strlen($password) < 8 || mb_strlen($password) > 128) {
            return response()->json(['error' => 'كلمة المرور يجب أن تكون بين 8 و128 حرفاً'], 422);
        }
        if (!in_array($role, ['parent', 'teacher', 'specialist'], true)) {
            return response()->json(['error' => 'الدور غير صالح'], 400);
        }
        if (
            $role === 'specialist'
            && $specialty !== null
            && !in_array(
                $specialty,
                ['learning_support', 'educational', 'communication_support', 'learning_behavior'],
                true
            )
        ) {
            return response()->json(['error' => 'التخصص غير صالح'], 422);
        }

        if (DB::table('users')->where('email', $email)->exists()) {
            return response()->json(['error' => 'الإيميل مستخدم مسبقاً'], 409);
        }

        try {
            $passwordColumn = $this->getPasswordColumn();
            if (!$passwordColumn) {
                return response()->json([
                    'error' => 'بنية جدول المستخدمين غير مكتملة على السيرفر',
                    'code' => 'AUTH_PASSWORD_COLUMN_MISSING',
                ], 500);
            }

            $insert = [
                'name' => $name,
                'email' => $email,
                $passwordColumn => password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]),
                'role' => $role,
            ];

            if (Schema::hasColumn('users', 'phone')) {
                $insert['phone'] = $phone;
            }
            if ($role === 'specialist' && $specialty && Schema::hasColumn('users', 'specialty')) {
                $insert['specialty'] = $specialty;
            }
            if ($request->filled('national_id') && Schema::hasColumn('users', 'national_id')) {
                $insert['national_id'] = trim((string) $request->input('national_id'));
            }

            $id = DB::table('users')->insertGetId($insert);
            $user = DB::table('users')->find($id);

            return response()->json([
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'phone' => Schema::hasColumn('users', 'phone') ? ($user->phone ?? null) : null,
                    'specialty' => Schema::hasColumn('users', 'specialty') ? ($user->specialty ?? null) : null,
                    'verification_status' => Schema::hasColumn('users', 'verification_status')
                        ? ($user->verification_status ?? 'pending')
                        : 'pending',
                ],
            ], 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
