<?php

namespace App\Console\Commands;

use App\Support\LessonFiles;
use App\Support\PrivateFileMigration;
use App\Support\R2Storage;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class PrivatizeLearningFiles extends Command
{
    protected $signature = 'edubridge:privatize-learning-files {--apply : Copy, verify, update references and remove public copies}';
    protected $description = 'Preview or migrate owned lesson media and homework submissions to private R2';
    private int $failures = 0;

    public function handle(): int
    {
        $this->failures = 0;
        if (!$this->option('apply')) {
            $lessons = DB::table('media')->pluck('url')->filter(fn ($url) => PrivateFileMigration::publicKey((string) $url) !== null)->count();
            $submissions = 0;
            DB::table('homework_submissions')->orderBy('id')->chunkById(100, function ($rows) use (&$submissions) {
                foreach ($rows as $row) foreach ($this->urls($row) as $url) {
                    if (str_starts_with(PrivateFileMigration::publicKey($url) ?? '', 'homework/')) $submissions++;
                }
            });
            $this->info("Preview: {$lessons} lesson objects, {$submissions} submission references. No changes. Use --apply after backup.");
            return self::SUCCESS;
        }
        if (R2Storage::privateBucket() === R2Storage::mediaBucket()) {
            $this->error('Private and public buckets must be different.');
            return self::FAILURE;
        }
        // First migrate references. Public deletion is a separate pass so shared files are safe.
        DB::table('media')->orderBy('id')->chunkById(100, function ($rows) {
            foreach ($rows as $row) $this->runSafely('media', $row->id, function () use ($row) {
                DB::transaction(function () use ($row) {
                    $current = DB::table('media')->where('id', $row->id)->lockForUpdate()->first();
                    $key = PrivateFileMigration::publicKey((string) ($current->url ?? ''));
                    if (!$current || !$key || !str_starts_with($key, "lessons/{$current->lesson_id}/")) return;
                    PrivateFileMigration::copy($key, $key);
                    DB::table('media')->where('id', $current->id)->update(['url' => LessonFiles::path($current->lesson_id, basename($key))]);
                });
            });
        });
        DB::table('homework_submissions')->orderBy('id')->chunkById(100, function ($rows) {
            foreach ($rows as $row) $this->runSafely('submission', $row->id, function () use ($row) {
                DB::transaction(function () use ($row) {
                    $current = DB::table('homework_submissions')->where('id', $row->id)->lockForUpdate()->first();
                    if (!$current) return;
                    $replacements = [];
                    foreach ($this->urls($current) as $url) {
                        $source = PrivateFileMigration::publicKey($url);
                        if (!$source || !str_starts_with($source, 'homework/')) continue;
                        $name = basename($source);
                        $destination = "homework/submissions/{$current->homework_id}/{$current->child_id}/{$name}";
                        PrivateFileMigration::copy($source, $destination);
                        $replacements[$url] = "/api/private-files/homework/{$current->homework_id}/child/{$current->child_id}/{$name}";
                    }
                    if (!$replacements) return;
                    $files = json_decode((string) ($current->file_urls ?? '[]'), true) ?: [];
                    DB::table('homework_submissions')->where('id', $current->id)->update([
                        'file_url' => $replacements[$current->file_url ?? ''] ?? $current->file_url,
                        'file_urls' => json_encode(array_map(fn ($url) => $replacements[$url] ?? $url, $files)),
                    ]);
                });
            });
        });
        // Retry-safe cleanup: private references retain enough information to locate old public objects.
        DB::table('media')->orderBy('id')->chunkById(100, function ($rows) {
            foreach ($rows as $row) if ($key = LessonFiles::key((string) $row->url)) {
                $this->runSafely('cleanup media', $row->id, fn () => $this->cleanup($key, $key));
            }
        });
        DB::table('homework_submissions')->orderBy('id')->chunkById(100, function ($rows) {
            foreach ($rows as $row) foreach ($this->urls($row) as $url) {
                $prefix = "/api/private-files/homework/{$row->homework_id}/child/{$row->child_id}/";
                if (!str_starts_with($url, $prefix)) continue;
                $name = substr($url, strlen($prefix));
                if (!LessonFiles::validFilename($name)) continue;
                $key = "homework/submissions/{$row->homework_id}/{$row->child_id}/{$name}";
                $this->runSafely('cleanup submission', $row->id, fn () => $this->cleanup('homework/' . $name, $key));
            }
        });
        $this->info('Migration finished; failures: ' . $this->failures . '. Rerun --apply to retry failed copies or cleanup.');
        return $this->failures ? self::FAILURE : self::SUCCESS;
    }

    private function urls(object $row): array
    {
        $urls = json_decode((string) ($row->file_urls ?? '[]'), true) ?: [];
        if ($row->file_url ?? null) $urls[] = $row->file_url;
        return array_values(array_unique(array_filter($urls, 'is_string')));
    }

    private function cleanup(string $source, string $destination): void
    {
        $url = R2Storage::mediaPublicUrl($source);
        if (DB::table('media')->where('url', $url)->exists()) return;
        $referenced = false;
        DB::table('homework_submissions')->orderBy('id')->chunkById(100, function ($rows) use ($url, &$referenced) {
            foreach ($rows as $row) if (in_array($url, $this->urls($row), true)) { $referenced = true; return false; }
        });
        if ($referenced) return;
        R2Storage::head(R2Storage::privateBucket(), $destination);
        R2Storage::delete(R2Storage::mediaBucket(), $source);
    }

    private function runSafely(string $kind, int $id, callable $work): void
    {
        try { $work(); } catch (\Throwable $e) {
            $this->failures++;
            report($e);
            $this->error("Failed {$kind} #{$id}; reference/public object retained where needed.");
        }
    }
}
