<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

final class SchoolInternalSession
{
    public static function active(int $user): bool
    {
        if (!Schema::hasTable('school_internal_identities')) return false;
        return DB::table('school_internal_identities as i')
            ->join('schools as s', 's.id', '=', 'i.school_id')
            ->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('i.user_id', $user)->where('s.is_active', true)
            ->whereNotNull('s.internal_domain_confirmed_at')
            ->when(Schema::hasColumn('school_internal_identities', 'is_active'), fn ($q) => $q->where('i.is_active', true))
            ->where(fn ($q) => $q->whereNull('s.organization_id')->orWhere('o.is_active', true))->exists();
    }
}
