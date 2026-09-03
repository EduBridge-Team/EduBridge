<?php

namespace App\Http\Controllers;

// رفع الملفات (صور الهوية، الشهادات، مستندات القرابة)
// يخزّن الملف في public/uploads ويعيد رابطاً عاماً يُخزَّن في قاعدة البيانات.
use Illuminate\Http\Request;

class UploadController extends Controller
{
    // صيغ الصور/المستندات المسموحة والحد الأقصى للحجم (5 ميغابايت)
    private const ALLOWED = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
    private const MAX_BYTES = 5 * 1024 * 1024;

    // POST /api/uploads   (multipart form-data، الحقل: file)
    public function store(Request $request)
    {
        $file = $request->file('file');
        if (!$file || !$file->isValid()) {
            return response()->json(['error' => 'الملف مطلوب'], 400);
        }

        $ext = strtolower($file->getClientOriginalExtension());
        if (!in_array($ext, self::ALLOWED, true)) {
            return response()->json(['error' => 'صيغة الملف غير مسموحة (jpg, png, webp, pdf)'], 422);
        }

        if ($file->getSize() > self::MAX_BYTES) {
            return response()->json(['error' => 'حجم الملف يتجاوز الحد الأقصى (5 ميغابايت)'], 422);
        }

        try {
            $dir = public_path('uploads');
            if (!is_dir($dir)) {
                @mkdir($dir, 0755, true);
            }

            // اسم فريد يمنع الكتابة فوق الملفات
            $name = date('Ymd_His') . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
            $file->move($dir, $name);

            return response()->json(['url' => '/uploads/' . $name], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر رفع الملف'], 500);
        }
    }
}
