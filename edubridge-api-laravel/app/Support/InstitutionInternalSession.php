<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

final class InstitutionInternalSession
{
    public static function resolve(string $identifier): ?object
    {
        $identifier = strtolower(trim($identifier));
        if (!preg_match('/^([a-z0-9][a-z0-9._-]{1,63})@([a-z][a-z0-9-]{2,39}\.edubridge)$/D', $identifier, $parts)
            || !Schema::hasTable('institution_internal_identities')
            || !Schema::hasColumn('organizations', 'internal_domain')) {
            return null;
        }

        $accounts = self::activeQuery()
            ->where('i.username', $parts[1])
            ->where('o.internal_domain', $parts[2])
            ->where('u.email', $identifier)
            ->select('u.*')->limit(2)->get();

        return $accounts->count() === 1 ? $accounts->first() : null;
    }

    public static function active(int $userId): bool
    {
        if (!Schema::hasTable('institution_internal_identities')
            || !Schema::hasColumn('organizations', 'internal_domain')) return false;

        return self::activeQuery()->where('i.user_id', $userId)
            ->whereRaw("lower(u.email) = (i.username || '@' || o.internal_domain)")
            ->exists();
    }

    public static function requiresPasswordChange(int $userId): bool
    {
        if (!Schema::hasTable('institution_internal_identities')) return false;

        return DB::table('institution_internal_identities')
            ->where('user_id', $userId)->where('must_change_password', true)->exists();
    }

    private static function activeQuery()
    {
        return DB::table('institution_internal_identities as i')
            ->join('organizations as o', 'o.id', '=', 'i.organization_id')
            ->join('users as u', 'u.id', '=', 'i.user_id')
            ->join('organization_user as ou', function ($join) {
                $join->on('ou.user_id', '=', 'i.user_id')
                    ->on('ou.organization_id', '=', 'i.organization_id');
            })
            ->where('o.is_active', true)
            ->where('i.is_active', true)
            ->where('ou.is_active', true)
            ->where('ou.role', 'teacher')
            ->where('u.role', 'teacher');
    }
}
