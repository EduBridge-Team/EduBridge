<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait AccountAvatarActions
{
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
}
