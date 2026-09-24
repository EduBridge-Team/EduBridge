<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;

trait HomeworkFileHelpers
{
    private function storeFiles(Request $request, string $field, string $prefix): array
    {
        $files = $request->file($field, []);

        if (!is_array($files)) {
            $files = [$files];
        }

        $urls = [];

        foreach ($files as $file) {
            if (!$file || !$file->isValid()) {
                continue;
            }

            $ext = strtolower($file->getClientOriginalExtension());

            if (!in_array($ext, self::ALLOWED_EXTENSIONS, true)) {
                throw new \RuntimeException('صيغة ملف غير مسموحة');
            }

            if ($file->getSize() > self::MAX_BYTES) {
                throw new \RuntimeException('حجم الملف يتجاوز 10 ميغابايت');
            }

            $name = $prefix
                . '_'
                . date('Ymd_His')
                . '_'
                . bin2hex(random_bytes(5))
                . '.'
                . $ext;
            $key = 'homework/' . $name;

            R2Storage::putUploadedFile(
                R2Storage::mediaBucket(),
                $key,
                $file,
                (string) $file->getMimeType()
            );

            $urls[] = R2Storage::mediaPublicUrl($key);
        }

        return $urls;
    }
}
