<?php

namespace App\Support;

use RuntimeException;

final class PrivateFileMigration
{
    public static function publicKey(string $url): ?string
    {
        $base = rtrim((string) env('R2_MEDIA_PUBLIC_URL'), '/');
        if ($base === '' || !str_starts_with($url, $base . '/')) return null;
        $key = rawurldecode(substr($url, strlen($base) + 1));
        if (!preg_match('#^(?:lessons/\d+/|homework/)([A-Za-z0-9._-]+)$#', $key, $m)
            || !LessonFiles::validFilename($m[1])) return null;
        return R2Storage::mediaPublicUrl($key) === $url ? $key : null;
    }

    public static function copy(string $source, string $destination): void
    {
        if (R2Storage::mediaBucket() === R2Storage::privateBucket()) {
            throw new RuntimeException('Private and public buckets must be different');
        }
        $object = R2Storage::get(R2Storage::mediaBucket(), $source);
        $path = tempnam(sys_get_temp_dir(), 'edubridge-private-');
        if ($path === false) throw new RuntimeException('Unable to create migration temporary file');
        $out = fopen($path, 'wb');
        if ($out === false) { unlink($path); throw new RuntimeException('Unable to write migration temporary file'); }
        try {
            $body = $object->getBody();
            while (!$body->eof()) {
                $chunk = $body->read(65536);
                if (fwrite($out, $chunk) !== strlen($chunk)) throw new RuntimeException('Incomplete migration download');
            }
            fclose($out); $out = null;
            $expected = $object->getHeaderLine('Content-Length');
            if ($expected !== '' && filesize($path) !== (int) $expected) throw new RuntimeException('Incomplete object');
            R2Storage::putLocalFile(R2Storage::privateBucket(), $destination, $path, $object->getHeaderLine('Content-Type'));
            $stored = R2Storage::head(R2Storage::privateBucket(), $destination);
            if ((int) $stored->getHeaderLine('Content-Length') !== filesize($path)) throw new RuntimeException('Private copy verification failed');
        } finally {
            if (is_resource($out)) fclose($out);
            unlink($path);
        }
    }
}
