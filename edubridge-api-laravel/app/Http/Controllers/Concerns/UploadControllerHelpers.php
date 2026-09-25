<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use GuzzleHttp\Exception\RequestException;

trait UploadControllerHelpers
{
    private function validFilename(string $filename): bool
    {
        return (bool) preg_match('/^[A-Za-z0-9._-]+$/', $filename)
            && !str_contains($filename, '..');
    }

    private function streamPrivateObject(string $key)
    {
        try {
            $object = R2Storage::get(R2Storage::privateBucket(), $key);
            $body = $object->getBody();

            $headers = [
                'Content-Type' => $object->getHeaderLine('Content-Type') ?: 'application/octet-stream',
                'X-Content-Type-Options' => 'nosniff',
                'Cache-Control' => 'private, no-store, max-age=0',
            ];

            $length = $object->getHeaderLine('Content-Length');
            if ($length !== '') {
                $headers['Content-Length'] = $length;
            }

            return response()->stream(function () use ($body) {
                while (!$body->eof()) {
                    echo $body->read(8192);
                }
            }, 200, $headers);
        } catch (RequestException $e) {
            if ($e->getResponse()?->getStatusCode() === 404) {
                return response()->json(['error' => 'الملف غير موجود'], 404);
            }

            report($e);

            return response()->json(['error' => 'تعذّر تحميل الملف'], 502);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر تحميل الملف'], 500);
        }
    }
}
