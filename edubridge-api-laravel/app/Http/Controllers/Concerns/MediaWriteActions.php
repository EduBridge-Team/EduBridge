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

            DB::table('media')->where('id', $id)->delete();

            if (is_string($media->url) && str_contains($media->url, '/lessons/')) {
                $path = parse_url($media->url, PHP_URL_PATH) ?: '';
                $key = ltrim($path, '/');

                if (str_starts_with($key, 'lessons/')) {
                    try {
                        R2Storage::delete(R2Storage::mediaBucket(), $key);
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
