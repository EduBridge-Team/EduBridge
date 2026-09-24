<?php

namespace App\Support;

use GuzzleHttp\Client;
use Psr\Http\Message\ResponseInterface;
use RuntimeException;

final class R2Storage
{
    public static function privateBucket(): string
    {
        return self::requiredEnv('R2_PRIVATE_BUCKET', env('AWS_BUCKET'));
    }

    public static function mediaBucket(): string
    {
        return self::requiredEnv('R2_MEDIA_BUCKET');
    }

    public static function mediaPublicUrl(string $key): string
    {
        $base = rtrim(self::requiredEnv('R2_MEDIA_PUBLIC_URL'), '/');
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
            self::request(
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
            self::request(
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
        self::request(
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
        return self::request('GET', $bucket, $key);
    }

    public static function delete(string $bucket, string $key): void
    {
        self::request('DELETE', $bucket, $key);
    }

    public static function head(string $bucket, string $key): ResponseInterface
    {
        return self::request('HEAD', $bucket, $key);
    }

    private static function request(
        string $method,
        string $bucket,
        string $key,
        $body = null,
        ?string $payloadHash = null,
        ?string $contentType = null
    ): ResponseInterface {
        $endpoint = rtrim(self::requiredEnv('AWS_ENDPOINT'), '/');
        $accessKey = self::requiredEnv('AWS_ACCESS_KEY_ID');
        $secretKey = self::requiredEnv('AWS_SECRET_ACCESS_KEY');
        $region = (string) env('AWS_DEFAULT_REGION', 'auto');

        $encodedKey = implode('/', array_map('rawurlencode', explode('/', ltrim($key, '/'))));
        $encodedBucket = rawurlencode($bucket);
        $url = $endpoint . '/' . $encodedBucket . '/' . $encodedKey;
        $payloadHash ??= hash('sha256', '');

        $headers = R2RequestSigner::headers(
            $method,
            $url,
            $payloadHash,
            $contentType,
            $accessKey,
            $secretKey,
            $region
        );

        $options = [
            'headers' => $headers,
            'http_errors' => true,
            'timeout' => 120,
            'connect_timeout' => 15,
        ];

        if ($body !== null) {
            $options['body'] = $body;
        }

        return (new Client())->request($method, $url, $options);
    }

    private static function requiredEnv(string $key, $fallback = null): string
    {
        $value = env($key, $fallback);
        if (!is_string($value) || trim($value) === '') {
            throw new RuntimeException($key . ' is not configured');
        }

        return trim($value);
    }
}
