<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

trait LessonControllerHelpers
{
    private function canTargetChildren($user, array $childIds): bool
    {
        if (!$user || !$childIds) {
            return false;
        }
    
        $childIds = array_values(array_unique(array_map('intval', $childIds)));
        if (DB::table('children')->whereIn('id', $childIds)->count() !== count($childIds)) {
            return false;
        }
    
        if (($user->role ?? null) === 'admin') {
            return true;
        }
    
        if (($user->role ?? null) === 'teacher') {
            $primary = DB::table('children')
                ->whereIn('id', $childIds)
                ->where('assigned_teacher_id', $user->id)
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->all();
    
            $team = DB::table('child_teacher')
                ->whereIn('child_id', $childIds)
                ->where('teacher_id', $user->id)
                ->pluck('child_id')
                ->map(fn ($id) => (int) $id)
                ->all();
    
            return count(array_unique(array_merge($primary, $team))) === count($childIds);
        }
    
        if (($user->role ?? null) === 'specialist') {
            return DB::table('child_specialist')
                ->whereIn('child_id', $childIds)
                ->where('specialist_id', $user->id)
                ->distinct()
                ->count('child_id') === count($childIds);
        }
    
        return false;
    }
    
    private function canManageLesson($user, $lesson): bool
    {
        if (!$user) {
            return false;
        }
    
        if (($user->role ?? null) === 'admin') {
            return true;
        }
    
        return (int) ($lesson->teacher_id ?? 0) === (int) ($user->id ?? 0);
    }
    
    private function deleteMediaByType(int $lessonId, string $type): void
    {
        $items = DB::table('media')
            ->where('lesson_id', $lessonId)
            ->where('type', $type)
            ->get(['id', 'url']);
    
        foreach ($items as $item) {
            $path = parse_url((string) $item->url, PHP_URL_PATH) ?: '';
            $key = ltrim($path, '/');
            if (str_starts_with($key, 'lessons/')) {
                try {
                    R2Storage::delete(R2Storage::mediaBucket(), $key);
                } catch (\Throwable $e) {
                    report($e);
                }
            }
        }
    
        DB::table('media')
            ->where('lesson_id', $lessonId)
            ->where('type', $type)
            ->delete();
    }
    
    private function imageFiles(Request $request): array
    {
        $images = $request->file('images', []);
        if (!is_array($images)) {
            $images = [$images];
        }
    
        $single = $request->file('image');
        if ($single) {
            $images[] = $single;
        }
    
        return array_values(array_filter($images, fn ($file) => $file && $file->isValid()));
    }
    
    private function parseTargetChildIds($raw): array
    {
        if ($raw === null || $raw === '') {
            return [];
        }
    
        if (is_string($raw)) {
            $decoded = json_decode($raw, true);
            $raw = is_array($decoded) ? $decoded : [];
        }
    
        if (!is_array($raw)) {
            return [];
        }
    
        return array_values(array_unique(array_filter(
            array_map('intval', $raw),
            fn ($id) => $id > 0
        )));
    }
    
    private function validateUploadedMedia(Request $request): void
    {
        foreach ($this->imageFiles($request) as $file) {
            $this->validateOneFile($file, 'image');
        }
    
        foreach (['video', 'audio', 'caption', 'sign_language'] as $type) {
            $file = $request->file($type);
            if ($file) {
                if (!$file->isValid()) {
                    throw new InvalidArgumentException('تعذّر قراءة ملف ' . $type);
                }
                $this->validateOneFile($file, $type);
            }
        }
    }
    
    private function validateOneFile($file, string $type): void
    {
        $rules = self::MEDIA_RULES[$type];
        $extension = strtolower((string) $file->getClientOriginalExtension());
    
        if (!in_array($extension, $rules['extensions'], true)) {
            throw new InvalidArgumentException(
                'صيغة ملف ' . $type . ' غير مدعومة. الصيغ المسموحة: ' .
                implode(', ', $rules['extensions'])
            );
        }
    
        if ((int) $file->getSize() > $rules['max_bytes']) {
            $maxMb = (int) ceil($rules['max_bytes'] / 1024 / 1024);
            throw new InvalidArgumentException("حجم ملف {$type} يتجاوز {$maxMb}MB");
        }
    }
    
    private function persistUploadedMedia($file, int $lessonId, string $type): void
    {
        $extension = strtolower((string) $file->getClientOriginalExtension());
        $filename = $type . '_' . bin2hex(random_bytes(10)) . '.' . $extension;
        $key = 'lessons/' . $lessonId . '/' . $filename;
    
        R2Storage::putUploadedFile(
            R2Storage::mediaBucket(),
            $key,
            $file,
            (string) $file->getMimeType()
        );
    
        DB::table('media')->insert([
            'lesson_id' => $lessonId,
            'type' => $type,
            'url' => R2Storage::mediaPublicUrl($key),
        ]);
    }
    
    private function serializeLesson(Request $request, $lesson): array
    {
        $data = (array) $lesson;
    
        if (array_key_exists('target_child_ids', $data)) {
            $raw = $data['target_child_ids'];
            if (is_string($raw)) {
                $decoded = json_decode($raw, true);
                $data['target_child_ids'] = is_array($decoded) ? $decoded : [];
            } elseif (!is_array($raw)) {
                $data['target_child_ids'] = [];
            }
        }
    
        $media = DB::table('media')
            ->where('lesson_id', $lesson->id)
            ->select('id', 'lesson_id', 'type', 'url')
            ->orderBy('id')
            ->get()
            ->map(function ($item) use ($request) {
                return [
                    'id' => $item->id,
                    'lesson_id' => $item->lesson_id,
                    'type' => $item->type,
                    'url' => $this->absoluteMediaUrl($request, $item->url),
                ];
            })
            ->values()
            ->all();
    
        $firstUrl = function (string $type) use ($media) {
            foreach ($media as $item) {
                if ($item['type'] === $type) {
                    return $item['url'];
                }
            }
            return null;
        };
    
        $images = array_values(array_map(
            fn ($item) => $item['url'],
            array_filter($media, fn ($item) => $item['type'] === 'image')
        ));
    
        $data['media'] = $media;
        $data['images'] = $images;
        $data['image_urls'] = $images;
        $data['video_url'] = $firstUrl('video');
        $data['audio_url'] = $firstUrl('audio');
        $data['caption_url'] = $firstUrl('caption');
        $data['sign_language_url'] = $firstUrl('sign_language');
    
        return $data;
    }
    
    private function absoluteMediaUrl(Request $request, ?string $url): ?string
    {
        if (!$url) {
            return null;
        }
        if (preg_match('/^https?:\/\//i', $url)) {
            return $url;
        }
    
        return rtrim($request->getSchemeAndHttpHost(), '/') . '/' . ltrim($url, '/');
    }
    
    private function removeLessonObjects(array $urls): void
    {
        foreach ($urls as $url) {
            $path = parse_url((string) $url, PHP_URL_PATH) ?: '';
            $key = ltrim($path, '/');
            if (!str_starts_with($key, 'lessons/')) {
                continue;
            }
    
            try {
                R2Storage::delete(R2Storage::mediaBucket(), $key);
            } catch (\Throwable $e) {
                report($e);
            }
        }
    }
}
