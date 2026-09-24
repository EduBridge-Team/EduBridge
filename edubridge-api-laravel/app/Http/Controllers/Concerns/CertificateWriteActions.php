<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CertificateWriteActions
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

    public function review(Request $request, $id)
    {
        $status = $request->input('status');
        if (!in_array($status, ['verified', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون verified أو rejected'], 400);
        }

        try {
            $certificate = DB::table('certificates')->where('id', $id)->first();
            if (!$certificate) {
                return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            }

            DB::table('certificates')->where('id', $id)->update([
                'status' => $status,
                'note' => $request->input('note'),
            ]);

            Notify::toUser(
                $certificate->user_id,
                $status === 'verified' ? 'تم اعتماد شهادتك' : 'تم رفض شهادتك',
                ($status === 'verified' ? 'تم اعتماد الشهادة: ' : 'تم رفض الشهادة: ')
                    . $certificate->title,
                'certificate'
            );

            return response()->json([
                'certificate' => DB::table('certificates')->find($id),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');

        try {
            $certificate = DB::table('certificates')->where('id', $id)->first();
            if (!$certificate) {
                return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            }
            if ($me->role !== 'admin' && (int) $certificate->user_id !== (int) $me->id) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            DB::table('certificates')->where('id', $id)->delete();

            $prefix = '/api/private-files/user/' . (int) $certificate->user_id . '/';
            if (is_string($certificate->url) && str_starts_with($certificate->url, $prefix)) {
                $filename = basename(parse_url($certificate->url, PHP_URL_PATH) ?: $certificate->url);

                if (preg_match('/^[A-Za-z0-9._-]+$/', $filename)) {
                    try {
                        R2Storage::delete(
                            R2Storage::privateBucket(),
                            'user-files/' . (int) $certificate->user_id . '/' . $filename
                        );
                    } catch (\Throwable $e) {
                        report($e);
                    }
                }
            }

            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
