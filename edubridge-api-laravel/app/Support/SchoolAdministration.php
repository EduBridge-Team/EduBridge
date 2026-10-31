<?php

namespace App\Support;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class SchoolAdministration
{
    public static function directorSchool(Request $request, bool $lock = false): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) return null;
        $query = DB::table('school_management_assignments as a')
            ->join('schools as s', 's.id', '=', 'a.school_id')
            ->where('a.user_id', $actor->id)->where('a.role', 'director')->whereNull('a.ends_at')
            ->where('s.is_active', true)
            ->where(fn ($q) => $q->whereNull('s.organization_id')->orWhereExists(fn ($o) => $o->selectRaw('1')->from('organizations')->whereColumn('organizations.id', 's.organization_id')->where('organizations.is_active', true)))
            ->select('s.*')->limit(2);
        $rows = $lock ? $query->lockForUpdate()->get() : $query->get();
        $school = $rows->count() === 1 ? $rows->first() : null;
        if ($school && $request->has('expected_school_id') && (int) $request->input('expected_school_id') !== (int) $school->id) return null;
        return $school;
    }

    public static function mayAppoint(?object $actor, object $school): bool
    {
        if (!$actor) return false;
        if (($actor->role ?? null) === 'admin') return true;
        if (($actor->role ?? null) !== 'institution' || $school->organization_id === null) return false;
        return DB::table('organizations')->where('id', $school->organization_id)->where('is_active', true)->exists()
            && DB::table('organization_user')->where('organization_id', $school->organization_id)
                ->where('user_id', $actor->id)->where('is_active', true)->whereIn('role', ['owner', 'admin'])->exists();
    }
}
