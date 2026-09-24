<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;

trait UploadWriteActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $file = $request->file('file');

        if (!$user) {
            return response()->json(['error' => 'غير مصرّح'], 401);
        }
        if (!$file || !$file->isValid()) {
            return response()->json(['error' => 'الملف مطلوب'], 400);
        }

        $ext = strtolower($file->getClientOriginalExtension());
        if (!in_array($ext, self::ALLOWED, true)) {
            return response()->json(['error' => 'صيغة الملف غير مسموحة (jpg, png, webp, pdf)'], 422);
        }

        $mime = strtolower((string) $file->getMimeType());
        if (!in_array($mime, self::ALLOWED_MIME, true)) {
            return response()->json(['error' => 'نوع الملف الفعلي غير مسموح'], 422);
        }

        if ($file->getSize() > self::MAX_BYTES) {
            return response()->json(['error' => 'حجم الملف يتجاوز الحد الأقصى (5 ميغابايت)'], 422);
        }

        try {
            $name = date('Ymd_His') . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
            $key = 'user-files/' . (int) $user->id . '/' . $name;

            R2Storage::putUploadedFile(
                R2Storage::privateBucket(),
                $key,
                $file,
                $mime
            );

            return response()->json([
                'url' => '/api/private-files/user/' . (int) $user->id . '/' . $name,
            ], 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر رفع الملف'], 500);
        }
    }
}
