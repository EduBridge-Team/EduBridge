<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class AccountController extends Controller
{
    private const EXTENSIONS = ['jpg','jpeg','png','webp'];
    private const MAX_BYTES = 5 * 1024 * 1024;

    public function uploadAvatar(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $file = $request->file('avatar');

        if (!$file || !$file->isValid()) {
            return response()->json(['error' => 'الصورة مطلوبة'], 422);
        }

        $ext = strtolower((string) $file->getClientOriginalExtension());
        if (!in_array($ext, self::EXTENSIONS, true)) {
            return response()->json(['error' => 'صيغة الصورة غير مدعومة'], 422);
        }
        if ((int) $file->getSize() > self::MAX_BYTES) {
            return response()->json(['error' => 'حجم الصورة يتجاوز 5MB'], 422);
        }

        try {
            $current = DB::table('users')->where('id', $user->id)->value('avatar_url');
            $dir = public_path('uploads/avatars');
            if (!is_dir($dir)) @mkdir($dir, 0755, true);

            $name = 'user_' . $user->id . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
            $file->move($dir, $name);
            $relative = '/uploads/avatars/' . $name;
            $absolute = rtrim($request->getSchemeAndHttpHost(), '/') . $relative;

            DB::table('users')->where('id', $user->id)->update(['avatar_url' => $absolute]);
            $this->deleteStoredAvatar($current, $relative);

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

        try {
            $current = DB::table('users')->where('id', $user->id)->value('avatar_url');
            DB::table('users')->where('id', $user->id)->delete();
            $this->deleteStoredAvatar($current);
            return response()->json(['message' => 'تم حذف الحساب']);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حذف الحساب'], 500);
        }
    }

    private function deleteStoredAvatar(?string $url, ?string $except = null): void
    {
        if (!$url || ($except && str_contains($url, $except))) return;

        $path = parse_url($url, PHP_URL_PATH) ?: $url;
        if (!str_starts_with($path, '/uploads/avatars/')) return;

        $full = public_path(ltrim($path, '/'));
        if (is_file($full)) @unlink($full);
    }
}
