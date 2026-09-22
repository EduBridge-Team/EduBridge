<?php

namespace App\Http\Controllers;

use App\Support\R2Storage;
use GuzzleHttp\Exception\RequestException;
use Illuminate\Http\Request;

class UploadController extends Controller
{
    private const ALLOWED = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
    private const ALLOWED_MIME = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf',
    ];
    private const MAX_BYTES = 5 * 1024 * 1024;

    // POST /api/uploads
    // الملفات الحساسة تحفظ في R2 الخاص وتُعرض فقط عبر endpoint مصادق عليه.
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

    // GET /api/private-files/child/{childId}/{filename}
    // مستندات هوية/قرابة الطفل: الأدمن أو ولي أمر مرتبط بالطفل فقط.
    public function showChild(Request $request, int $childId, string $filename)
    {
        $user = $request->attributes->get('jwt_user');
        $allowed = $user && (
            $user->role === 'admin'
            || ($user->role === 'parent'
                && \Illuminate\Support\Facades\DB::table('child_parent')
                    ->where('child_id', $childId)
                    ->where('parent_id', $user->id)
                    ->exists())
        );

        if (!$allowed) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!$this->validFilename($filename)) {
            return response()->json(['error' => 'اسم ملف غير صالح'], 400);
        }

        return $this->streamPrivateObject('child-files/' . $childId . '/' . $filename);
    }

    // GET /api/private-files/user/{userId}/{filename}
    // صاحب الملف أو الأدمن فقط.
    public function show(Request $request, int $userId, string $filename)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || ($user->role !== 'admin' && (int) $user->id !== $userId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!$this->validFilename($filename)) {
            return response()->json(['error' => 'اسم ملف غير صالح'], 400);
        }

        return $this->streamPrivateObject('user-files/' . $userId . '/' . $filename);
    }

    private function validFilename(string $filename): bool
    {
        return (bool) preg_match('/^[A-Za-z0-9._-]+$/', $filename)
            && !str_contains($filename, '..');
    }

    private function streamPrivateObject(string $key)
    {
        try {
            $object = R2Storage::get(R2Storage::privateBucket(), $key);
            $body = $object->getBody();

            $headers = [
                'Content-Type' => $object->getHeaderLine('Content-Type') ?: 'application/octet-stream',
                'X-Content-Type-Options' => 'nosniff',
                'Cache-Control' => 'private, no-store, max-age=0',
            ];

            $length = $object->getHeaderLine('Content-Length');
            if ($length !== '') {
                $headers['Content-Length'] = $length;
            }

            return response()->stream(function () use ($body) {
                while (!$body->eof()) {
                    echo $body->read(8192);
                }
            }, 200, $headers);
        } catch (RequestException $e) {
            if ($e->getResponse()?->getStatusCode() === 404) {
                return response()->json(['error' => 'الملف غير موجود'], 404);
            }
            report($e);
            return response()->json(['error' => 'تعذّر تحميل الملف'], 502);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل الملف'], 500);
        }
    }
}
