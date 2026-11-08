<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use RuntimeException;

final class SubjectCode
{
    public static function normalize(?string $code): ?string
    {
        if ($code === null) {
            return null;
        }

        $normalized = strtoupper(trim($code));

        return $normalized === '' ? null : $normalized;
    }

    /**
     * The single SQL expression used for API validation, legacy preflight and
     * the database unique index. It mirrors PHP trim's common ASCII whitespace.
     * PostgreSQL is production; SQLite is used by the isolated test suite.
     */
    public static function normalizedSql(): string
    {
        [$trim, $character] = match (DB::connection()->getDriverName()) {
            'pgsql' => ['BTRIM', 'CHR'],
            'sqlite' => ['TRIM', 'CHAR'],
            default => throw new RuntimeException('Unsupported database for subject-code uniqueness'),
        };

        $whitespace = "' ' || {$character}(9) || {$character}(10) || {$character}(11) || {$character}(12) || {$character}(13)";

        return "NULLIF(UPPER({$trim}(code, {$whitespace})), '')";
    }
}
