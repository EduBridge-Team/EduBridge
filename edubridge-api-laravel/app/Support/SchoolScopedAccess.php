<?php

namespace App\Support;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class SchoolScopedAccess
{
    public const PERMISSIONS = ['academic', 'enrollment', 'attendance', 'timetable', 'curriculum', 'reports'];

    public static function resolve(Request $request, string $permission): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) return null;
        if (($actor->role ?? null) === 'school') {
            $query = DB::table('school_accounts as a')->join('schools as s', 's.id', '=', 'a.school_id')
                ->where('a.user_id', $actor->id)->select('s.*');
        } else {
            $query = DB::table('school_management_assignments as a')->join('schools as s', 's.id', '=', 'a.school_id')
                ->where('a.user_id', $actor->id)->whereIn('a.role', ['director', 'deputy_director'])->whereNull('a.ends_at')
                ->select('s.*', 'a.role as management_role');
            if (\Illuminate\Support\Facades\Schema::hasColumn('school_management_assignments', 'permissions')) {
                $query->addSelect('a.permissions as delegated_permissions');
            }
        }
        $schools = $query->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('s.is_active', true)
            ->where(fn ($q) => $q->whereNull('s.organization_id')->orWhere('o.is_active', true))
            ->limit(101)->get();
        if ($schools->count() > 100 || $schools->groupBy('id')->count() !== 1) return null;
        $school = $schools->firstWhere('management_role', 'director') ?? $schools->first();
        if (($school->management_role ?? null) === 'deputy_director') {
            $permissions = json_decode($school->delegated_permissions ?? '[]', true);
            if ($permission !== 'context' && (!is_array($permissions) || !in_array($permission, $permissions, true))) return null;
        }
        return $school;
    }
}
