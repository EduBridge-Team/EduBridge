<?php

namespace App\Console\Commands;

use App\Support\R2Storage;
use Illuminate\Console\Command;
use GuzzleHttp\Client;

class CheckR2Storage extends Command
{
    protected $signature = 'edubridge:r2-check';
    protected $description = 'Verify EduBridge private and media Cloudflare R2 buckets';

    public function handle(): int
    {
        $payload = 'EduBridge R2 check ' . now()->toIso8601String();

        foreach ([
            'private' => R2Storage::privateBucket(),
            'media' => R2Storage::mediaBucket(),
        ] as $label => $bucket) {
            $key = 'healthchecks/' . $label . '-' . bin2hex(random_bytes(6)) . '.txt';

            try {
                $this->line("Checking {$label} bucket: {$bucket}");
                R2Storage::putString($bucket, $key, $payload);

                $response = R2Storage::get($bucket, $key);
                $received = (string) $response->getBody();

                if ($received !== $payload) {
                    throw new \RuntimeException('Read-back content did not match');
                }

                if ($label === 'media') {
                    $publicUrl = R2Storage::mediaPublicUrl($key);
                    $public = (new Client([
                        'timeout' => 20,
                        'connect_timeout' => 10,
                        'http_errors' => false,
                    ]))->get($publicUrl);

                    if ($public->getStatusCode() !== 200 || (string) $public->getBody() !== $payload) {
                        throw new \RuntimeException('Public media URL check failed: ' . $publicUrl);
                    }

                    $this->info("OK: public media URL reachable at " . rtrim((string) env('R2_MEDIA_PUBLIC_URL'), '/'));
                }

                R2Storage::delete($bucket, $key);
                $this->info("OK: {$label} bucket read/write/delete succeeded.");
            } catch (\Throwable $e) {
                $this->error("FAILED: {$label} bucket: " . $e->getMessage());
                report($e);
                return self::FAILURE;
            }
        }

        $this->info('R2 storage is configured correctly.');
        return self::SUCCESS;
    }
}
