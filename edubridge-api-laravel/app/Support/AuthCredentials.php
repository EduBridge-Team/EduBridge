<?php

namespace App\Support;

final class AuthCredentials
{
    public static function issue(object $account, string $secret): string
    {
        return \Firebase\JWT\JWT::encode([
            'id' => (int) $account->id,
            'role' => $account->role,
            'iat' => time(),
            'exp' => time() + 7 * 24 * 3600,
            'session_version' => (int) ($account->session_version ?? 0),
            'credential_stamp' => self::stamp($account, $secret),
        ], $secret, 'HS256');
    }

    public static function stamp(object $account, string $secret): string
    {
        // A keyed fingerprint exposes neither the password nor its stored hash.
        // Password changes invalidate tokens without a deployment-time migration.
        return hash_hmac('sha256', (string) ($account->password_hash ?? $account->password ?? ''), $secret);
    }
}
