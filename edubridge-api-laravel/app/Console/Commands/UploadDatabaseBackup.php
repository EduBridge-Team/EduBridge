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
            R2Storage::putLocalFile(
                R2Storage::privateBucket(),
                $key,
                $path,
                'application/octet-stream'
            );
        } catch (RuntimeException $e) {
            $this->error($e->getMessage());
            return self::FAILURE;
        }

        $this->info("Uploaded database backup to private R2: {$key}");
        return self::SUCCESS;
    }
}
