<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

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
    // الملفات الحساسة تحفظ خارج public وتُعرض فقط عبر endpoint مصادق عليه.
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
            $dir = storage_path('app/private/user-files/' . (int) $user->id);
            if (!is_dir($dir)) {
                @mkdir($dir, 0750, true);
            }

            $name = date('Ymd_His') . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
            $file->move($dir, $name);

            return response()->json([
                'url' => '/api/private-files/user/' . (int) $user->id . '/' . $name,
            ], 201);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر رفع الملف'], 500);
        }
    }

    // GET /api/private-files/user/{userId}/{filename}
    // صاحب الملف أو الأدمن فقط.
    public function show(Request $request, int $userId, string $filename): BinaryFileResponse|\Illuminate\Http\JsonResponse
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || ($user->role !== 'admin' && (int) $user->id !== $userId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!preg_match('/^[A-Za-z0-9._-]+$/', $filename) || str_contains($filename, '..')) {
            return response()->json(['error' => 'اسم ملف غير صالح'], 400);
        }

        $path = storage_path('app/private/user-files/' . $userId . '/' . $filename);
        if (!is_file($path)) {
            return response()->json(['error' => 'الملف غير موجود'], 404);
        }

        return response()->file($path, [
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store, max-age=0',
        ]);
    }
}
