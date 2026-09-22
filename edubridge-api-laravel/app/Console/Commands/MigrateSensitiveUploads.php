<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class MigrateSensitiveUploads extends Command
{
    protected $signature = 'edubridge:migrate-sensitive-uploads
        {--apply : Perform the migration instead of dry-run}
        {--delete-public : Delete migrated public files after references are updated}';

    protected $description = 'Move legacy identity, kinship, and certificate files from public uploads into private storage';

    private int $migrated = 0;
    private int $missing = 0;
    private int $skipped = 0;
    private array $deleteCandidates = [];

    public function handle(): int
    {
        $apply = (bool) $this->option('apply');
        $deletePublic = $apply && (bool) $this->option('delete-public');

        $this->info($apply ? 'Applying sensitive upload migration...' : 'Dry run only. Use --apply to migrate files.');

        $this->migrateUserIdentities($apply, $deletePublic);
        $this->migrateCertificates($apply, $deletePublic);
        $this->migrateChildDocuments($apply, $deletePublic);

        if ($deletePublic) {
            $this->purgeUnreferencedPublicFiles();
        }

        $this->newLine();
        $this->info("Migrated: {$this->migrated}; missing: {$this->missing}; skipped: {$this->skipped}");

        if (!$apply) {
            $this->warn('No files or database rows were changed.');
        }

        return self::SUCCESS;
    }

    private function legacyPath(?string $url): ?string
    {
        if (!$url) return null;

        $path = parse_url($url, PHP_URL_PATH) ?: $url;
        if (!is_string($path) || !str_starts_with($path, '/uploads/')) {
            return null;
        }

        if (str_contains($path, '..')) return null;

        $relative = ltrim($path, '/');
        $absolute = public_path($relative);
        $realPublic = realpath(public_path());
        $realParent = realpath(dirname($absolute));

        if (!$realPublic || !$realParent || !str_starts_with($realParent, $realPublic)) {
            return null;
        }

        return $absolute;
    }

    private function safeName(string $source, string $prefix): string
    {
        $ext = strtolower(pathinfo($source, PATHINFO_EXTENSION));
        $ext = preg_match('/^[a-z0-9]{1,8}$/', $ext) ? $ext : 'bin';

        return $prefix . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
    }

    private function copyToPrivate(string $source, string $targetDir, string $name, bool $apply): bool
    {
        if (!is_file($source)) {
            $this->warn("Missing: {$source}");
            $this->missing++;
            return false;
        }

        $target = $targetDir . DIRECTORY_SEPARATOR . $name;
        $this->line(($apply ? 'MOVE' : 'WOULD MOVE') . " {$source} -> {$target}");

        if (!$apply) {
            $this->migrated++;
            return true;
        }

        if (!is_dir($targetDir) && !mkdir($targetDir, 0750, true) && !is_dir($targetDir)) {
            throw new \RuntimeException("Cannot create private directory: {$targetDir}");
        }

        if (!copy($source, $target)) {
            throw new \RuntimeException("Cannot copy legacy file: {$source}");
        }

        @chmod($target, 0640);
        $this->migrated++;
        return true;
    }

    private function queueDelete(string $source, ?string $legacyUrl, bool $deletePublic): void
    {
        if (!$deletePublic || !is_file($source) || !$legacyUrl) return;

        $normalized = str_replace('\\', '/', $source);
        foreach (['/uploads/avatars/', '/uploads/lessons/', '/uploads/homework/'] as $safePublic) {
            if (str_contains($normalized, $safePublic)) return;
        }

        $this->deleteCandidates[$source] = $legacyUrl;
    }

    private function purgeUnreferencedPublicFiles(): void
    {
        foreach ($this->deleteCandidates as $source => $legacyUrl) {
            $stillReferenced =
                DB::table('users')->where('id_document_url', $legacyUrl)->exists()
                || DB::table('certificates')->where('url', $legacyUrl)->exists()
                || DB::table('children')->where('guardian_id_document_url', $legacyUrl)->exists()
                || DB::table('children')->where('kinship_document_url', $legacyUrl)->exists();

            if (!$stillReferenced && is_file($source)) {
                @unlink($source);
                $this->line("DELETED {$source}");
            } elseif ($stillReferenced) {
                $this->warn("Kept referenced public file: {$source}");
            }
        }
    }

    private function migrateUserIdentities(bool $apply, bool $deletePublic): void
    {
        DB::table('users')
            ->whereNotNull('id_document_url')
            ->orderBy('id')
            ->get(['id', 'id_document_url'])
            ->each(function ($row) use ($apply, $deletePublic) {
                $source = $this->legacyPath($row->id_document_url);
                if (!$source) {
                    $this->skipped++;
                    return;
                }

                $name = $this->safeName($source, 'identity');
                $dir = storage_path('app/private/user-files/' . (int) $row->id);

                if (!$this->copyToPrivate($source, $dir, $name, $apply)) return;

                $newUrl = '/api/private-files/user/' . (int) $row->id . '/' . $name;
                if ($apply) {
                    DB::table('users')->where('id', $row->id)->update(['id_document_url' => $newUrl]);
                    $this->queueDelete($source, (string) $row->id_document_url, $deletePublic);
                }
            });
    }

    private function migrateCertificates(bool $apply, bool $deletePublic): void
    {
        DB::table('certificates')
            ->whereNotNull('url')
            ->orderBy('id')
            ->get(['id', 'user_id', 'url'])
            ->each(function ($row) use ($apply, $deletePublic) {
                $source = $this->legacyPath($row->url);
                if (!$source) {
                    $this->skipped++;
                    return;
                }

                $name = $this->safeName($source, 'certificate');
                $dir = storage_path('app/private/user-files/' . (int) $row->user_id);

                if (!$this->copyToPrivate($source, $dir, $name, $apply)) return;

                $newUrl = '/api/private-files/user/' . (int) $row->user_id . '/' . $name;
                if ($apply) {
                    DB::table('certificates')->where('id', $row->id)->update(['url' => $newUrl]);
                    $this->queueDelete($source, (string) $row->url, $deletePublic);
                }
            });
    }

    private function migrateChildDocuments(bool $apply, bool $deletePublic): void
    {
        DB::table('children')
            ->orderBy('id')
            ->get(['id', 'guardian_id_document_url', 'kinship_document_url'])
            ->each(function ($row) use ($apply, $deletePublic) {
                foreach (['guardian_id_document_url' => 'guardian', 'kinship_document_url' => 'kinship'] as $field => $prefix) {
                    $url = $row->$field ?? null;
                    $source = $this->legacyPath($url);
                    if (!$source) {
                        if ($url) $this->skipped++;
                        continue;
                    }

                    $name = $this->safeName($source, $prefix);
                    $dir = storage_path('app/private/child-files/' . (int) $row->id);

                    if (!$this->copyToPrivate($source, $dir, $name, $apply)) continue;

                    $newUrl = '/api/private-files/child/' . (int) $row->id . '/' . $name;
                    if ($apply) {
                        DB::table('children')->where('id', $row->id)->update([$field => $newUrl]);
                        $this->queueDelete($source, (string) $url, $deletePublic);
                    }
                }
            });
    }
}
