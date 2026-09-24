<?php

namespace App\Support;

use GuzzleHttp\Client;
use Psr\Http\Message\ResponseInterface;
use RuntimeException;

final class R2StorageTransport
{
    public static function request(
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

    public static function requiredEnv(string $key, $fallback = null): string
    {
        $value = env($key, $fallback);
        if (!is_string($value) || trim($value) === '') {
            throw new RuntimeException($key . ' is not configured');
        }

        return trim($value);
    }
}
