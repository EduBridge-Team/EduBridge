<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

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

        $internal = Schema::hasTable('institution_internal_identities')
            && DB::table('institution_internal_identities')->where('user_id', $userId)->exists();
        if (mb_strlen($newPassword) < ($internal ? 12 : 8) || mb_strlen($newPassword) > 128) {
            return response()->json([
                'error' => $internal ? 'كلمة المرور الجديدة يجب أن تكون بين 12 و128 حرفاً' : 'كلمة المرور الجديدة يجب أن تكون بين 8 و128 حرفاً',
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

        DB::transaction(function () use ($userId, $newPassword, $passwordColumn, $internal) {
            $hash = password_hash($newPassword, PASSWORD_BCRYPT, ['cost' => 10]);
            $changes = [$passwordColumn => $hash];
            if ($internal) {
                if (Schema::hasColumn('users', 'password')) $changes['password'] = $hash;
                if (Schema::hasColumn('users', 'password_hash')) $changes['password_hash'] = $hash;
                DB::table('institution_internal_identities')->where('user_id', $userId)
                    ->update(['must_change_password' => false, 'updated_at' => now()]);
            }
            DB::table('users')->where('id', $userId)->update($changes);
        });

        $account = DB::table('users')->find($userId);
        $secret = config('services.jwt.secret') ?: env('JWT_SECRET');
        return response()->json(['message' => 'تم تغيير كلمة المرور بنجاح',
            'token' => \App\Support\AuthCredentials::issue($account, $secret)]);
    }
}
