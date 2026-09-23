<?php

namespace App\Console\Commands;

use App\Support\R2Storage;
use GuzzleHttp\Client;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class MigrateLegacyPublicMediaToR2 extends Command
{
    protected $signature = 'edubridge:migrate-public-media-to-r2
        {--source=https://edubridge.alwaysdata.net : Legacy public base URL}
        {--apply : Upload files and update database references}';

    protected $description = 'Move legacy public lesson media, avatars, and homework files from the old host to the EduBridge media R2 bucket';

    private Client $http;
    private int $migrated = 0;
    private int $missing = 0;
    private int $skipped = 0;
    private int $failed = 0;

    public function handle(): int
    {
        $this->http = new Client(['timeout' => 180, 'connect_timeout' => 15, 'http_errors' => false]);
        $apply = (bool) $this->option('apply');
        $source = rtrim((string) $this->option('source'), '/');

        $this->info($apply ? 'Applying public media migration...' : 'Dry run only. Use --apply to migrate.');
        $this->line('Legacy source: ' . $source);
        $this->line('R2 bucket: ' . R2Storage::mediaBucket());

        $this->migrateLessonMedia($source, $apply);
        $this->migrateAvatars($source, $apply);
        $this->migrateHomeworkAttachments($source, $apply);
        $this->migrateHomeworkSubmissions($source, $apply);

        $this->newLine();
        $this->info("Migrated: {$this->migrated}; missing: {$this->missing}; skipped: {$this->skipped}; failed: {$this->failed}");

        if (!$apply) {
            $this->warn('Dry run only. No R2 objects or database rows were changed.');
        }

        return $this->failed === 0 ? self::SUCCESS : self::FAILURE;
    }

    private function migrateLessonMedia(string $source, bool $apply): void
    {
        DB::table('media')->orderBy('id')->get(['id', 'url'])->each(function ($row) use ($source, $apply) {
            $newUrl = $this->migrateUrl((string) $row->url, $source, $apply);
            if ($apply && $newUrl && $newUrl !== $row->url) {
                DB::table('media')->where('id', $row->id)->update(['url' => $newUrl]);
            }
        });
    }

    private function migrateAvatars(string $source, bool $apply): void
    {
        DB::table('users')->whereNotNull('avatar_url')->orderBy('id')->get(['id', 'avatar_url'])->each(function ($row) use ($source, $apply) {
            $newUrl = $this->migrateUrl((string) $row->avatar_url, $source, $apply);
            if ($apply && $newUrl && $newUrl !== $row->avatar_url) {
                DB::table('users')->where('id', $row->id)->update(['avatar_url' => $newUrl]);
            }
        });
    }

    private function migrateHomeworkAttachments(string $source, bool $apply): void
    {
        DB::table('homeworks')->orderBy('id')->get(['id', 'attachment_urls'])->each(function ($row) use ($source, $apply) {
            $urls = $this->decodeUrls($row->attachment_urls);
            if (!$urls) return;

            $changed = false;
            foreach ($urls as $i => $url) {
                $newUrl = $this->migrateUrl((string) $url, $source, $apply);
                if ($newUrl && $newUrl !== $url) {
                    $urls[$i] = $newUrl;
                    $changed = true;
                }
            }

            if ($apply && $changed) {
                DB::table('homeworks')->where('id', $row->id)->update([
                    'attachment_urls' => json_encode(array_values($urls)),
                ]);
            }
        });
    }

    private function migrateHomeworkSubmissions(string $source, bool $apply): void
    {
        DB::table('homework_submissions')->orderBy('id')->get(['id', 'file_urls', 'file_url'])->each(function ($row) use ($source, $apply) {
            $urls = $this->decodeUrls($row->file_urls);
            $changed = false;

            foreach ($urls as $i => $url) {
                $newUrl = $this->migrateUrl((string) $url, $source, $apply);
                if ($newUrl && $newUrl !== $url) {
                    $urls[$i] = $newUrl;
                    $changed = true;
                }
            }

            $single = $row->file_url;
            $newSingle = $single ? $this->migrateUrl((string) $single, $source, $apply) : null;

            if ($apply && ($changed || ($newSingle && $newSingle !== $single))) {
                DB::table('homework_submissions')->where('id', $row->id)->update([
                    'file_urls' => json_encode(array_values($urls)),
                    'file_url' => $newSingle ?: $single,
                ]);
            }
        });
    }

    private function decodeUrls($raw): array
    {
        if (!$raw) return [];
        if (is_array($raw)) return $raw;
        $decoded = json_decode((string) $raw, true);
        return is_array($decoded) ? array_values($decoded) : [];
    }

    private function migrateUrl(string $url, string $source, bool $apply): ?string
    {
        if ($url === '' || str_starts_with($url, rtrim((string) env('R2_MEDIA_PUBLIC_URL'), '/') . '/')) {
            $this->skipped++;
            return $url;
        }

        $path = parse_url($url, PHP_URL_PATH) ?: $url;
        if (!is_string($path) || !str_starts_with($path, '/uploads/')) {
            $this->skipped++;
            return $url;
        }

        $key = $this->r2KeyFromLegacyPath($path);
        if (!$key) {
            $this->skipped++;
            return $url;
        }

        $legacyUrl = preg_match('/^https?:\/\//i', $url) ? $url : $source . $path;
        $newUrl = R2Storage::mediaPublicUrl($key);

        $this->line(($apply ? 'MIGRATE' : 'WOULD MIGRATE') . " {$legacyUrl} -> {$newUrl}");

        if (!$apply) {
            $this->migrated++;
            return $newUrl;
        }

        $tmp = tempnam(sys_get_temp_dir(), 'edubridge-media-');
        if ($tmp === false) {
            $this->failed++;
            return $url;
        }

        try {
            $response = $this->http->request('GET', $legacyUrl, ['sink' => $tmp]);
            if ($response->getStatusCode() === 404) {
                $this->warn('Missing: ' . $legacyUrl);
                $this->missing++;
                return $url;
            }
            if ($response->getStatusCode() < 200 || $response->getStatusCode() >= 300) {
                throw new \RuntimeException('Legacy download returned HTTP ' . $response->getStatusCode());
            }

            $type = $response->getHeaderLine('Content-Type') ?: null;
            R2Storage::putLocalFile(R2Storage::mediaBucket(), $key, $tmp, $type);

            $head = R2Storage::head(R2Storage::mediaBucket(), $key);
            if ((int) $head->getHeaderLine('Content-Length') !== (int) filesize($tmp)) {
                throw new \RuntimeException('R2 size verification failed');
            }

            $this->migrated++;
            return $newUrl;
        } catch (\Throwable $e) {
            $this->failed++;
            $this->error('FAILED ' . $legacyUrl . ': ' . $e->getMessage());
            report($e);
            return $url;
        } finally {
            @unlink($tmp);
        }
    }

    private function r2KeyFromLegacyPath(string $path): ?string
    {
        if (preg_match('#^/uploads/lessons/(.+)$#', $path, $m)) {
            return 'lessons/' . ltrim($m[1], '/');
        }
        if (preg_match('#^/uploads/avatars/(.+)$#', $path, $m)) {
            return 'avatars/' . ltrim($m[1], '/');
        }
        if (preg_match('#^/uploads/homework/(.+)$#', $path, $m)) {
            return 'homework/' . ltrim($m[1], '/');
        }
        return null;
    }
}
