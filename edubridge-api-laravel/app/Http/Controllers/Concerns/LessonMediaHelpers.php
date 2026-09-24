<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

trait LessonMediaHelpers
{
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

        return array_values(array_filter(
            $images,
            fn ($file) => $file && $file->isValid()
        ));
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
                'صيغة ملف ' . $type . ' غير مدعومة. الصيغ المسموحة: '
                . implode(', ', $rules['extensions'])
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
