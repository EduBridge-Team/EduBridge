<?php

namespace App\Support;

use GuzzleHttp\Client;
use Psr\Http\Message\ResponseInterface;
use RuntimeException;

final class R2Storage
{
    public static function privateBucket(): string
    {
        return R2StorageTransport::requiredEnv('R2_PRIVATE_BUCKET', env('AWS_BUCKET'));
    }

    public static function mediaBucket(): string
    {
        return R2StorageTransport::requiredEnv('R2_MEDIA_BUCKET');
    }

    public static function mediaPublicUrl(string $key): string
    {
        $base = rtrim(R2StorageTransport::requiredEnv('R2_MEDIA_PUBLIC_URL'), '/');
        $encoded = implode('/', array_map('rawurlencode', explode('/', ltrim($key, '/'))));

        return $base . '/' . $encoded;
    }

    public static function putUploadedFile(
        string $bucket,
        string $key,
        $file,
        ?string $contentType = null
    ): void {
        $path = $file->getRealPath();
        if (!$path || !is_file($path)) {
            throw new RuntimeException('Uploaded file is not readable');
        }

        $stream = fopen($path, 'rb');
        if ($stream === false) {
            throw new RuntimeException('Unable to open uploaded file');
        }

        try {
            R2StorageTransport::request(
                'PUT',
                $bucket,
                $key,
                $stream,
                hash_file('sha256', $path),
                $contentType ?: (string) $file->getMimeType()
            );
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }
    }

    public static function putLocalFile(
        string $bucket,
        string $key,
        string $path,
        ?string $contentType = null
    ): void {
        if (!is_file($path) || !is_readable($path)) {
            throw new RuntimeException('Local file is not readable: ' . $path);
        }

        $stream = fopen($path, 'rb');
        if ($stream === false) {
            throw new RuntimeException('Unable to open local file: ' . $path);
        }

        try {
            R2StorageTransport::request(
                'PUT',
                $bucket,
                $key,
                $stream,
                hash_file('sha256', $path),
                $contentType ?: (string) (mime_content_type($path) ?: 'application/octet-stream')
            );
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }
    }

    public static function putString(
        string $bucket,
        string $key,
        string $contents,
        string $contentType = 'text/plain'
    ): void {
        R2StorageTransport::request(
            'PUT',
            $bucket,
            $key,
            $contents,
            hash('sha256', $contents),
            $contentType
        );
    }

    public static function get(string $bucket, string $key): ResponseInterface
    {
        return R2StorageTransport::request('GET', $bucket, $key);
    }

    public static function delete(string $bucket, string $key): void
    {
        R2StorageTransport::request('DELETE', $bucket, $key);
    }

    public static function head(string $bucket, string $key): ResponseInterface
    {
        return R2StorageTransport::request('HEAD', $bucket, $key);
    }

}
