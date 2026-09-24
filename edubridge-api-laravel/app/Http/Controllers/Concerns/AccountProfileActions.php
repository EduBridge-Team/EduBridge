<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait AccountProfileActions
{
    public function me(Request $request)
    {
        $jwtUser = $request->attributes->get('jwt_user');
        $userId = is_object($jwtUser) ? ($jwtUser->id ?? null) : null;

        if (!$userId) {
            return response()->json(['error' => 'تعذّر تحديد المستخدم الحالي'], 401);
        }

        $user = DB::table('users')->where('id', $userId)->first();
        if (!$user) {
            return response()->json(['error' => 'المستخدم غير موجود'], 404);
        }

        $profile = [
            'id' => $user->id,
            'name' => $user->name ?? null,
            'email' => $user->email ?? null,
            'role' => $user->role ?? ($jwtUser->role ?? null),
            'phone' => Schema::hasColumn('users', 'phone') ? ($user->phone ?? null) : null,
            'specialty' => Schema::hasColumn('users', 'specialty') ? ($user->specialty ?? null) : null,
            'verification_status' => Schema::hasColumn('users', 'verification_status')
                ? ($user->verification_status ?? 'pending')
                : 'pending',
            'created_at' => $user->created_at ?? null,
        ];

        if (Schema::hasColumn('users', 'avatar_url')) {
            $profile['avatar_url'] = $user->avatar_url ?? null;
        }

        $profile['is_verified'] = ($profile['verification_status'] ?? 'pending') === 'verified';

        return response()->json(['user' => $profile]);
    }

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
            return response()->json(['error' => 'كلمة المرور الحالية والجديدة مطلوبتان'], 422);
        }

        if (mb_strlen($newPassword) < 8) {
            return response()->json(['error' => 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل'], 422);
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

    public function destroy(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || empty($user->id)) {
            return response()->json(['error' => 'المستخدم غير موجود'], 404);
        }

        try {
            $current = DB::table('users')->where('id', $user->id)->value('avatar_url');

            DB::transaction(function () use ($user) {
                $deleted = DB::table('users')->where('id', $user->id)->delete();

                if ($deleted !== 1) {
                    throw new \RuntimeException('Account row was not deleted');
                }
            });

            $this->deleteStoredAvatar($current);

            return response()->json([
                'message' => 'تم حذف الحساب والبيانات المرتبطة به',
                'deleted' => true,
            ]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حذف الحساب'], 500);
        }
    }
}
