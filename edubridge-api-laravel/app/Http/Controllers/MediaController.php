<?php

namespace App\Http\Controllers;

// وسائط الدروس (صور / فيديو / صوت) — مرتبطة بدرس
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MediaController extends Controller
{
    private const TYPES = ['image', 'video', 'audio'];

    // عرض وسائط درس معيّن
    // GET /api/lessons/:id/media
    public function index($lessonId)
    {
        try {
            $media = DB::table('media')
                ->where('lesson_id', $lessonId)
                ->select('id', 'lesson_id', 'type', 'url')
                ->get();

            return response()->json(['media' => $media]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إضافة وسيط لدرس (معلّم / أدمن)
    // POST /api/lessons/:id/media   body: { type, url }
    public function store(Request $request, $lessonId)
    {
        $type = $request->input('type');
        $url = $request->input('url');

        if (!$type || !$url) {
            return response()->json(['error' => 'النوع والرابط مطلوبان'], 400);
        }
        if (!in_array($type, self::TYPES, true)) {
            return response()->json(['error' => 'نوع الوسيط غير صالح'], 400);
        }

        try {
            if (!DB::table('lessons')->where('id', $lessonId)->exists()) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }

            $id = DB::table('media')->insertGetId([
                'lesson_id' => $lessonId,
                'type' => $type,
                'url' => $url,
            ]);

            return response()->json(['media' => DB::table('media')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // حذف وسيط (معلّم / أدمن)
    // DELETE /api/media/:id
    public function destroy($id)
    {
        try {
            if (!DB::table('media')->where('id', $id)->exists()) {
                return response()->json(['error' => 'الوسيط غير موجود'], 404);
            }

            DB::table('media')->where('id', $id)->delete();
            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
