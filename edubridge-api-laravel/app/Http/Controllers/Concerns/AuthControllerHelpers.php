<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use App\Support\AuthCredentials;

trait AuthControllerHelpers
{
    private function getJwtSecret(): ?string
    {
        $secret = config('services.jwt.secret') ?: env('JWT_SECRET') ?: getenv('JWT_SECRET') ?: ($_ENV['JWT_SECRET'] ?? null);
        $secret = is_string($secret) ? trim($secret) : null;

        return $secret !== '' ? $secret : null;
    }

    private function getGoogleClientId(): ?string
    {
        return env('GOOGLE_CLIENT_ID') ?: getenv('GOOGLE_CLIENT_ID') ?: ($_ENV['GOOGLE_CLIENT_ID'] ?? null);
    }

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

    private function issueToken(object $user): string
    {
        $jwtSecret = $this->getJwtSecret();
        if (!$jwtSecret) {
            throw new \RuntimeException('JWT_SECRET_MISSING');
        }

        $role = isset($user->role) && is_string($user->role) ? trim($user->role) : '';
        if ($role === '') {
            throw new \RuntimeException('USER_ROLE_MISSING');
        }

        $account = DB::table('users')->where('id', $user->id)->first();
        if (!$account) {
            throw new \RuntimeException('USER_NOT_FOUND');
        }

        return AuthCredentials::issue($account, $jwtSecret);
    }
}
