<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CertificateUploadActions
{
    public function store(Request $request)
    {
        $me = $request->attributes->get('jwt_user');

        $title = trim((string) $request->input('title'));
        $url = trim((string) $request->input('url', ''));
        $file = $request->file('file');

        if ($title === '') {
            return response()->json(['error' => 'عنوان الشهادة مطلوب'], 400);
        }

        if ($file) {
            if (!$file->isValid()) {
                return response()->json(['error' => 'تعذّر قراءة ملف الشهادة'], 422);
            }

            $ext = strtolower((string) $file->getClientOriginalExtension());
            if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'pdf'], true)) {
                return response()->json(['error' => 'صيغة الشهادة غير مدعومة'], 422);
            }
            if ((int) $file->getSize() > 10 * 1024 * 1024) {
                return response()->json(['error' => 'حجم الشهادة يتجاوز 10MB'], 422);
            }

            $mime = strtolower((string) $file->getMimeType());
            if (!in_array($mime, ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'], true)) {
                return response()->json(['error' => 'نوع ملف الشهادة غير مدعوم'], 422);
            }

            $name = 'certificate_' . $me->id . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
            $key = 'user-files/' . (int) $me->id . '/' . $name;

            R2Storage::putUploadedFile(
                R2Storage::privateBucket(),
                $key,
                $file,
                $mime
            );

            $url = '/api/private-files/user/' . (int) $me->id . '/' . $name;
        }

        if ($url === '') {
            return response()->json(['error' => 'ملف الشهادة مطلوب'], 400);
        }

        $expectedPrefix = '/api/private-files/user/' . (int) $me->id . '/';
        if (!str_starts_with($url, $expectedPrefix)) {
            return response()->json(['error' => 'يجب رفع ملف الشهادة من خلال التخزين الآمن'], 422);
        }

        try {
            $id = DB::table('certificates')->insertGetId([
                'user_id' => $me->id,
                'title' => $title,
                'url' => $url,
            ]);

            return response()->json([
                'certificate' => DB::table('certificates')->find($id),
            ], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
