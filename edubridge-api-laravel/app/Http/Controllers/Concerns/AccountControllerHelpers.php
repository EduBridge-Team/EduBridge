<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Support\Facades\Schema;

trait AccountControllerHelpers
{
    private function getPasswordColumn(): ?string
    {
        if (Schema::hasColumn('users', 'password_hash')) {
            return 'password_hash';
        }

        if (Schema::hasColumn('users', 'password')) {
            return 'password';
        }

        return null;
    }

    private function deleteStoredAvatar(?string $url, ?string $except = null): void
    {
        if (!$url || ($except && str_contains($url, $except))) {
            return;
        }

        $path = parse_url($url, PHP_URL_PATH) ?: '';
        $key = ltrim($path, '/');

        if (!str_starts_with($key, 'avatars/')) {
            return;
        }

        try {
            R2Storage::delete(R2Storage::mediaBucket(), $key);
        } catch (\Throwable $e) {
            report($e);
        }
    }
}
