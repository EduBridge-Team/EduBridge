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

    public static function putUploadedFile(string $bucket, string $key, $file, ?string $contentType = null): void
    {
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
            fclose($stream);
        }
    }

    public static function putString(string $bucket, string $key, string $contents, string $contentType = 'text/plain'): void
    {
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

        $parts = parse_url($url);
        if (!$parts || empty($parts['host'])) {
            throw new RuntimeException('Invalid R2 endpoint');
        }

        $host = $parts['host'] . (isset($parts['port']) ? ':' . $parts['port'] : '');
        $canonicalUri = $parts['path'] ?? '/';
        $payloadHash ??= hash('sha256', '');

        $now = gmdate('Ymd\THis\Z');
        $date = substr($now, 0, 8);

        $headers = [
            'host' => $host,
            'x-amz-content-sha256' => $payloadHash,
            'x-amz-date' => $now,
        ];
        if ($contentType) {
            $headers['content-type'] = $contentType;
        }
        ksort($headers);

        $canonicalHeaders = '';
        foreach ($headers as $name => $value) {
            $canonicalHeaders .= strtolower($name) . ':' . trim((string) $value) . "\n";
        }
        $signedHeaders = implode(';', array_keys($headers));

        $canonicalRequest = strtoupper($method) . "\n"
            . $canonicalUri . "\n"
            . "\n"
            . $canonicalHeaders . "\n"
            . $signedHeaders . "\n"
            . $payloadHash;

        $scope = $date . '/' . $region . '/s3/aws4_request';
        $stringToSign = "AWS4-HMAC-SHA256\n"
            . $now . "\n"
            . $scope . "\n"
            . hash('sha256', $canonicalRequest);

        $kDate = hash_hmac('sha256', $date, 'AWS4' . $secretKey, true);
        $kRegion = hash_hmac('sha256', $region, $kDate, true);
        $kService = hash_hmac('sha256', 's3', $kRegion, true);
        $kSigning = hash_hmac('sha256', 'aws4_request', $kService, true);
        $signature = hash_hmac('sha256', $stringToSign, $kSigning);

        $requestHeaders = [
            'Host' => $host,
            'x-amz-content-sha256' => $payloadHash,
            'x-amz-date' => $now,
            'Authorization' => 'AWS4-HMAC-SHA256 Credential=' . $accessKey . '/' . $scope
                . ', SignedHeaders=' . $signedHeaders
                . ', Signature=' . $signature,
        ];
        if ($contentType) {
            $requestHeaders['Content-Type'] = $contentType;
        }

        $options = [
            'headers' => $requestHeaders,
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
