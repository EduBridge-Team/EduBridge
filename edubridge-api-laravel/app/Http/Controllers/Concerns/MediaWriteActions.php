<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

trait MediaWriteActions
{
    public function store(Request $request, $lessonId)
    {
        $user = $request->attributes->get('jwt_user');
        $type = (string) $request->input('type');

        if (!in_array($type, self::TYPES, true)) {
            return response()->json(['error' => 'نوع الوسيط غير صالح'], 422);
        }

        try {
            $lesson = DB::table('lessons')->where('id', $lessonId)->first();
            if (!$lesson) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }
            if (!$this->canManageLesson($user, $lesson)) {
                return response()->json(['error' => 'لا يمكنك تعديل وسائط درس لم تقم بإنشائه'], 403);
            }

            $url = $request->input('url');
            $file = $request->file('file');

            if ($file) {
                if (!$file->isValid()) {
                    return response()->json(['error' => 'تعذّر قراءة الملف'], 422);
                }

                $this->validateFile($file, $type);
                $url = $this->storeFile($file, (int) $lessonId, $type);
            }

            if (!$file && ($lesson->target_type ?? null) === 'specificChildren') {
                return response()->json(['error' => 'ارفع الملف لحمايته في درس موجّه لأطفال محددين'], 422);
            }
            if (!$file && ($ownedKey = \App\Support\PrivateFileMigration::publicKey((string) $url))
                && !str_starts_with($ownedKey, "lessons/{$lessonId}/")) {
                return response()->json(['error' => 'رابط الملف لا يخص هذا الدرس'], 422);
            }
            if (!$file && !filter_var($url, FILTER_VALIDATE_URL)) {
                return response()->json(['error' => 'رابط غير صالح'], 422);
            }
            if (!$file && !in_array(strtolower(parse_url($url, PHP_URL_SCHEME) ?: ''), ['http', 'https'], true)) {
                return response()->json(['error' => 'رابط غير صالح'], 422);
            }
            if (!$url) {
                return response()->json(['error' => 'الملف أو الرابط مطلوب'], 400);
            }

            $id = DB::table('media')->insertGetId([
                'lesson_id' => $lessonId,
                'type' => $type,
                'url' => $url,
            ]);

            $media = DB::table('media')->find($id);
            $media->url = $this->absoluteUrl($request, $media->url);

            return response()->json(['media' => $media], 201);
        } catch (InvalidArgumentException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $media = DB::table('media')->where('id', $id)->first();
            if (!$media) {
                return response()->json(['error' => 'الوسيط غير موجود'], 404);
            }

            $lesson = DB::table('lessons')->where('id', $media->lesson_id)->first();
            if (!$lesson) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }
            if (!$this->canManageLesson($user, $lesson)) {
                return response()->json(['error' => 'لا يمكنك حذف وسائط درس لم تقم بإنشائه'], 403);
            }

            try {
                DB::transaction(function () use ($id, $media) {
                    DB::table('media')->where('id', $id)->delete();
                    // Roll back the media reference if R2 refuses to delete the file.
                    // LessonFiles checks for other references before deleting shared objects.
                    \App\Support\LessonFiles::delete((string) $media->url);
                });
            } catch (\Throwable $e) {
                report($e);
                return response()->json(['error' => 'تعذّر حذف الملف من التخزين، لم يُحذف الوسيط'], 502);
            }

            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
