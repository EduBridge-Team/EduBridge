<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use InvalidArgumentException;

class MediaController extends Controller
{
    private const TYPES = ['image', 'video', 'audio', 'caption', 'sign_language'];

    private const RULES = [
        'image' => [['jpg', 'jpeg', 'png', 'webp'], 10 * 1024 * 1024],
        'video' => [['mp4', 'webm', 'mov', 'm4v'], 150 * 1024 * 1024],
        'audio' => [['mp3', 'm4a', 'aac', 'wav', 'ogg'], 50 * 1024 * 1024],
        'caption' => [['vtt', 'srt'], 5 * 1024 * 1024],
        'sign_language' => [['mp4', 'webm', 'mov', 'm4v'], 150 * 1024 * 1024],
    ];

    // عرض وسائط درس معيّن
    // GET /api/lessons/:id/media
    public function index(Request $request, $lessonId)
    {
        try {
            $media = DB::table('media')
                ->where('lesson_id', $lessonId)
                ->select('id', 'lesson_id', 'type', 'url')
                ->orderBy('id')
                ->get()
                ->map(function ($item) use ($request) {
                    $item->url = $this->absoluteUrl($request, $item->url);
                    return $item;
                });

            return response()->json(['media' => $media]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إضافة وسيط لدرس.
    // يدعم body: {type,url} للتوافق القديم أو multipart: type + file.
    public function store(Request $request, $lessonId)
    {
        $type = (string) $request->input('type');
        if (!in_array($type, self::TYPES, true)) {
            return response()->json(['error' => 'نوع الوسيط غير صالح'], 422);
        }

        try {
            if (!DB::table('lessons')->where('id', $lessonId)->exists()) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
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

    // حذف وسيط (معلّم / أدمن)
    // DELETE /api/media/:id
    public function destroy($id)
    {
        try {
            $media = DB::table('media')->where('id', $id)->first();
            if (!$media) {
                return response()->json(['error' => 'الوسيط غير موجود'], 404);
            }

            DB::table('media')->where('id', $id)->delete();

            if (is_string($media->url) && str_starts_with($media->url, '/uploads/lessons/')) {
                $path = public_path(ltrim($media->url, '/'));
                if (is_file($path)) {
                    File::delete($path);
                }
            }

            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    private function validateFile($file, string $type): void
    {
        [$extensions, $maxBytes] = self::RULES[$type];
        $extension = strtolower((string) $file->getClientOriginalExtension());

        if (!in_array($extension, $extensions, true)) {
            throw new InvalidArgumentException(
                'صيغة الملف غير مدعومة. الصيغ المسموحة: ' . implode(', ', $extensions)
            );
        }

        if ((int) $file->getSize() > $maxBytes) {
            $maxMb = (int) ceil($maxBytes / 1024 / 1024);
            throw new InvalidArgumentException("حجم الملف يتجاوز {$maxMb}MB");
        }
    }

    private function storeFile($file, int $lessonId, string $type): string
    {
        $extension = strtolower((string) $file->getClientOriginalExtension());
        $directory = public_path('uploads/lessons/' . $lessonId);

        if (!is_dir($directory)) {
            @mkdir($directory, 0755, true);
        }

        $filename = $type . '_' . bin2hex(random_bytes(10)) . '.' . $extension;
        $file->move($directory, $filename);

        return '/uploads/lessons/' . $lessonId . '/' . $filename;
    }

    private function absoluteUrl(Request $request, ?string $url): ?string
    {
        if (!$url) {
            return null;
        }
        if (preg_match('/^https?:\/\//i', $url)) {
            return $url;
        }
        return rtrim($request->getSchemeAndHttpHost(), '/') . '/' . ltrim($url, '/');
    }
}
