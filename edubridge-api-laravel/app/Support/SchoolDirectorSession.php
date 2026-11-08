<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

/**
 * School-director accounts have no independent operator privileges:
 * the active, unambiguous appointment and active school/organization grant
 * their scope. Call on login AND on every authenticated request.
 *
 * Never grant access by a user-supplied school ID or by a historic appointment.
 */
final class SchoolDirectorSession
{
    public static function active(int $userId): bool
    {
        return DB::table('school_management_assignments as appointment')
            ->join('schools as school', 'school.id', '=', 'appointment.school_id')
            ->leftJoin('organizations as organization', 'organization.id', '=', 'school.organization_id')
            ->where('appointment.user_id', $userId)
            ->where('appointment.role', 'director')
            ->whereNull('appointment.ends_at')
            ->where('school.is_active', true)
            ->where(function ($query) {
                $query->whereNull('school.organization_id')
                    ->orWhere('organization.is_active', true);
            })
            ->limit(2)
            ->count() === 1;
    }
    /**
     * Revoke only the outgoing dedicated director's previously issued JWTs.
     * A legacy teacher or other user's unrelated sessions are not touched.
     * Called inside the school appointment transaction after taking its lock.
     */
    public static function revoke(int $userId): void
    {
        DB::table('users')->where('id', $userId)->where('role', 'school_director')
            ->update(['session_version' => DB::raw('session_version + 1')]);
    }
}
