<?php

namespace App\Http\Controllers\Concerns;

trait LegacyMobileHelpers
{
    private function encodeId(int $sourceId, int $type): int
    {
        return $sourceId * 10 + $type;
    }

    private function decodeId(int $id): array
    {
        return [intdiv($id, 10), $id % 10];
    }
}
