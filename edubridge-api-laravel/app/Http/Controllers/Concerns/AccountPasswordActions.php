<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait AccountPasswordActions
{
    public function changePassword(Request $request)
    {
        $jwtUser = $request->attributes->get('jwt_user');
        $userId = is_object($jwtUser) ? ($jwtUser->id ?? null) : null;

        if (!$userId) {
            return response()->json(['error' => 'تعذّر تحديد المستخدم الحالي'], 401);
        }

        $currentPassword = (string) $request->input('current_password', '');
        $newPassword = (string) $request->input('new_password', '');

        if ($currentPassword === '' || $newPassword === '') {
            return response()->json([
                'error' => 'كلمة المرور الحالية والجديدة مطلوبتان',
            ], 422);
        }

        if (mb_strlen($newPassword) < 8) {
            return response()->json([
                'error' => 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل',
            ], 422);
        }

        $passwordColumn = $this->getPasswordColumn();
        if (!$passwordColumn) {
            return response()->json([
                'error' => 'بنية جدول المستخدمين غير مكتملة على السيرفر',
                'code' => 'AUTH_PASSWORD_COLUMN_MISSING',
            ], 500);
        }

        $user = DB::table('users')->where('id', $userId)->first();
        $storedHash = $user?->{$passwordColumn} ?? null;

        if (!$user || !is_string($storedHash) || !password_verify($currentPassword, $storedHash)) {
            return response()->json(['error' => 'كلمة المرور الحالية غير صحيحة'], 422);
        }

        DB::table('users')->where('id', $userId)->update([
            $passwordColumn => password_hash($newPassword, PASSWORD_BCRYPT, ['cost' => 10]),
        ]);

        return response()->json(['message' => 'تم تغيير كلمة المرور بنجاح']);
    }
}
