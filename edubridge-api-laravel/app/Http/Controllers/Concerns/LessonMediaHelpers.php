<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

trait LessonMediaHelpers
{
    private array $newLessonObjects = [];
    private array $replacedLessonObjects = [];

    private function beginLessonMedia(): void
    {
        $this->newLessonObjects = [];
        $this->replacedLessonObjects = [];
    }

    private function commitLessonMedia(): void
    {
        $this->removeLessonObjects($this->replacedLessonObjects);
        $this->beginLessonMedia();
    }

    private function rollbackLessonMedia(): void
    {
        $this->removeLessonObjects($this->newLessonObjects);
        $this->beginLessonMedia();
    }

    private function deleteMediaByType(int $lessonId, string $type): void
    {
        $items = DB::table('media')
            ->where('lesson_id', $lessonId)
            ->where('type', $type)
            ->get(['id', 'url']);

        // Object deletion is delayed until the database transaction commits.
        foreach ($items as $item) $this->replacedLessonObjects[] = $item->url;

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
        $url = \App\Support\LessonFiles::path($lessonId, $filename);

        R2Storage::putUploadedFile(
            R2Storage::privateBucket(),
            $key,
            $file,
            (string) $file->getMimeType()
        );
        $this->newLessonObjects[] = $url;

        DB::table('media')->insert([
            'lesson_id' => $lessonId,
            'type' => $type,
            'url' => $url,
        ]);
    }

    private function removeLessonObjects(array $urls): void
    {
        foreach ($urls as $url) {
            try {
                \App\Support\LessonFiles::delete((string) $url);
            } catch (\Throwable $e) {
                report($e);
            }
        }
    }
}
