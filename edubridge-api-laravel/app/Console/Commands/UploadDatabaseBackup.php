<?php

namespace App\Console\Commands;

use App\Support\R2Storage;
use Illuminate\Console\Command;
use RuntimeException;

class UploadDatabaseBackup extends Command
{
    protected $signature = 'edubridge:upload-database-backup
        {path : Absolute path to the dump file inside the container}
        {--key= : Optional R2 object key}';

    protected $description = 'Upload a verified PostgreSQL dump to the private EduBridge R2 bucket';

    public function handle(): int
    {
        $path = (string) $this->argument('path');
        if (!is_file($path) || !is_readable($path)) {
            $this->error("Backup file is not readable: {$path}");
            return self::FAILURE;
        }

        if (filesize($path) === 0) {
            $this->error('Backup file is empty.');
            return self::FAILURE;
        }

        $key = (string) ($this->option('key') ?: 'database-backups/' . basename($path));

        try {
            $bucket = R2Storage::privateBucket();
            $expectedHash = hash_file('sha256', $path);
            if ($expectedHash === false) {
                throw new RuntimeException('Unable to hash local backup file');
            }

            R2Storage::putLocalFile($bucket, $key, $path, 'application/octet-stream');

            // Verify the exact remote object, not just the successful PUT response.
            // Read in fixed-size chunks to avoid loading a full database dump into RAM.
            $remote = R2Storage::get($bucket, $key);
            $body = $remote->getBody();
            $hash = hash_init('sha256');
            while (!$body->eof()) {
                $chunk = $body->read(65536);
                if ($chunk === '') {
                    throw new RuntimeException('Unable to read back complete R2 backup');
                }
                hash_update($hash, $chunk);
            }
            if (!hash_equals($expectedHash, hash_final($hash))) {
                throw new RuntimeException('R2 backup checksum mismatch after upload');
            }
        } catch (\Throwable $e) {
            $this->error($e->getMessage());
            return self::FAILURE;
        }

        $this->info("Uploaded and verified database backup in private R2: {$key}");
        return self::SUCCESS;
    }
}
