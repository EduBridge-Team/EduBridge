<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use InvalidArgumentException;

trait MediaControllerHelpers
{
    private function canManageLesson($user, $lesson): bool
    {
        if (!$user || !$lesson) {
            return false;
        }
        if (($user->role ?? null) === 'admin') {
            return true;
        }

        return (int) ($lesson->teacher_id ?? 0) === (int) ($user->id ?? 0);
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
        $filename = $type . '_' . bin2hex(random_bytes(10)) . '.' . $extension;
        $key = 'lessons/' . $lessonId . '/' . $filename;

        R2Storage::putUploadedFile(
            R2Storage::mediaBucket(),
            $key,
            $file,
            (string) $file->getMimeType()
        );

        return R2Storage::mediaPublicUrl($key);
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
