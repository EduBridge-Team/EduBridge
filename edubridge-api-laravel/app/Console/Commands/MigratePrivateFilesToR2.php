<?php

namespace App\Console\Commands;

use App\Support\R2Storage;
use Illuminate\Console\Command;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use FilesystemIterator;

class MigratePrivateFilesToR2 extends Command
{
    protected $signature = 'edubridge:migrate-private-to-r2
        {--apply : Upload files to R2 instead of dry-run}
        {--delete-local : Delete each local file only after a successful R2 upload}';

    protected $description = 'Copy existing private user/child files to the EduBridge private R2 bucket while preserving keys';

    private int $copied = 0;
    private int $missing = 0;
    private int $skipped = 0;
    private int $failed = 0;

    public function handle(): int
    {
        $apply = (bool) $this->option('apply');
        $deleteLocal = $apply && (bool) $this->option('delete-local');
        $bucket = R2Storage::privateBucket();

        $this->info($apply ? "Uploading private files to R2 bucket: {$bucket}" : "Dry run for R2 bucket: {$bucket}");

        $roots = [
            'user-files' => storage_path('app/private/user-files'),
            'child-files' => storage_path('app/private/child-files'),
        ];

        foreach ($roots as $prefix => $root) {
            if (!is_dir($root)) {
                $this->warn("Missing local directory: {$root}");
                $this->missing++;
                continue;
            }

            $iterator = new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)
            );

            foreach ($iterator as $file) {
                if (!$file->isFile()) {
                    continue;
                }

                $absolute = $file->getPathname();
                $relative = ltrim(str_replace('\\', '/', substr($absolute, strlen($root))), '/');
                if ($relative === '' || str_contains($relative, '..')) {
                    $this->skipped++;
                    continue;
                }

                $key = $prefix . '/' . $relative;
                $this->line(($apply ? 'UPLOAD' : 'WOULD UPLOAD') . " {$absolute} -> r2://{$bucket}/{$key}");

                if (!$apply) {
                    $this->copied++;
                    continue;
                }

                try {
                    $uploaded = new class($absolute) {
                        public function __construct(private string $path) {}
                        public function getRealPath(): string { return $this->path; }
                        public function getMimeType(): string {
                            return (string) (mime_content_type($this->path) ?: 'application/octet-stream');
                        }
                    };

                    R2Storage::putUploadedFile($bucket, $key, $uploaded);

                    $head = R2Storage::head($bucket, $key);
                    $remoteSize = (int) $head->getHeaderLine('Content-Length');
                    $localSize = (int) filesize($absolute);

                    if ($remoteSize !== $localSize) {
                        throw new \RuntimeException("Size verification failed for {$key}: local={$localSize}, remote={$remoteSize}");
                    }

                    $this->copied++;

                    if ($deleteLocal) {
                        @unlink($absolute);
                        $this->line("DELETED LOCAL {$absolute}");
                    }
                } catch (\Throwable $e) {
                    $this->failed++;
                    $this->error("FAILED {$key}: " . $e->getMessage());
                    report($e);
                }
            }
        }

        $this->newLine();
        $this->info("Copied: {$this->copied}; missing dirs: {$this->missing}; skipped: {$this->skipped}; failed: {$this->failed}");

        if (!$apply) {
            $this->warn('Dry run only. No files were uploaded or deleted.');
        }

        return $this->failed === 0 ? self::SUCCESS : self::FAILURE;
    }
}
