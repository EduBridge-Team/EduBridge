<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Support\R2Storage;

class AccountController extends Controller
{
    private const MIME_EXTENSIONS = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];
    private const MAX_BYTES = 5 * 1024 * 1024;

    public function uploadAvatar(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $file = $request->file('avatar');

        if (!$file || !$file->isValid()) {
            return response()->json(['error' => 'الصورة مطلوبة'], 422);
        }

        if ((int) $file->getSize() > self::MAX_BYTES) {
            return response()->json(['error' => 'حجم الصورة يتجاوز 5MB'], 422);
        }

        $imageInfo = @getimagesize($file->getRealPath());
        $mime = strtolower((string) ($imageInfo['mime'] ?? ''));
        $ext = self::MIME_EXTENSIONS[$mime] ?? null;
        if (!$imageInfo || !$ext) {
            return response()->json(['error' => 'الملف المرفوع ليس صورة مدعومة'], 422);
        }

        try {
            $current = DB::table('users')->where('id', $user->id)->value('avatar_url');

            $name = 'user_' . $user->id . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
            $key = 'avatars/' . $name;
            R2Storage::putUploadedFile(
                R2Storage::mediaBucket(),
                $key,
                $file,
                $mime
            );
            $absolute = R2Storage::mediaPublicUrl($key);

            DB::table('users')->where('id', $user->id)->update(['avatar_url' => $absolute]);
            $this->deleteStoredAvatar($current, $absolute);

            return response()->json(['avatar_url' => $absolute]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحديث الصورة'], 500);
        }
    }

    public function removeAvatar(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $current = DB::table('users')->where('id', $user->id)->value('avatar_url');
            DB::table('users')->where('id', $user->id)->update(['avatar_url' => null]);
            $this->deleteStoredAvatar($current);
            return response()->json(['ok' => true]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حذف الصورة'], 500);
        }
    }

    public function destroy(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || empty($user->id)) {
            return response()->json(['error' => 'المستخدم غير موجود'], 404);
        }

        try {
            $current = DB::table('users')->where('id', $user->id)->value('avatar_url');

            // Delete the account atomically. Database foreign keys cascade or
            // null dependent references so partial account deletion cannot occur.
            DB::transaction(function () use ($user) {
                $deleted = DB::table('users')->where('id', $user->id)->delete();

                if ($deleted !== 1) {
                    throw new \RuntimeException('Account row was not deleted');
                }
            });

            // Filesystem cleanup happens only after the database transaction commits.
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

    private function deleteStoredAvatar(?string $url, ?string $except = null): void
    {
        if (!$url || ($except && str_contains($url, $except))) return;

        $path = parse_url($url, PHP_URL_PATH) ?: '';
        $key = ltrim($path, '/');
        if (!str_starts_with($key, 'avatars/')) return;

        try {
            R2Storage::delete(R2Storage::mediaBucket(), $key);
        } catch (\Throwable $e) {
            report($e);
        }
    }

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
    
    // تغيير كلمة مرور المستخدم الحالي
    // PUT /api/me/password
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
}
