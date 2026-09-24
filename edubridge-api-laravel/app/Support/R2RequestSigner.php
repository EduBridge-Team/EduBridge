<?php

namespace App\Support;

use RuntimeException;

final class R2RequestSigner
{
    public static function headers(
        string $method,
        string $url,
        string $payloadHash,
        ?string $contentType,
        string $accessKey,
        string $secretKey,
        string $region
    ): array {
        $parts = parse_url($url);
        if (!$parts || empty($parts['host'])) {
            throw new RuntimeException('Invalid R2 endpoint');
        }

        $host = $parts['host'] . (isset($parts['port']) ? ':' . $parts['port'] : '');
        $canonicalUri = $parts['path'] ?? '/';

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

        return $requestHeaders;
    }
}
