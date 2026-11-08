<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Mirrors existing verified invitation activation into the institution's
 * profile/history directory. The established school_management_assignments
 * table remains the only source of operational login/role permissions.
 */
final class InstitutionDirectorDirectorySync
{
    public static function activated(object $school, object $invite, int $userId, string $name): void
    {
        // Older isolated fixtures may deliberately use only the legacy tables.
        if (!Schema::hasTable('institution_director_profiles')
            || !Schema::hasTable('institution_director_assignments')) return;

        // Caller already holds a lock on the school's row.
        $today = now()->toDateString();
        $email = mb_strtolower(trim((string) $invite->email));
        $profile = DB::table('institution_director_profiles')
            ->where('school_id', $school->id)->whereRaw('LOWER(email) = ?', [$email])
            ->first();
        if ($profile) {
            $profileId = (int) $profile->id;
            DB::table('institution_director_profiles')->where('id', $profileId)->update([
                'identity_user_id' => $userId,
                'updated_by' => $invite->invited_by,
                'updated_at' => now(),
            ]);
        } else {
            $profileId = DB::table('institution_director_profiles')->insertGetId([
                'school_id' => $school->id, 'name' => trim($name),
                'email' => $email, 'phone' => '', 'qualification' => '',
                'experience_years' => 0, 'identity_user_id' => $userId,
                'created_by' => $invite->invited_by, 'updated_by' => $invite->invited_by,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }

        $current = DB::table('institution_director_assignments')
            ->where('school_id', $school->id)->whereNull('ended_on')->first();
        if ($current && (int) $current->director_id === $profileId) {
            // An organization may have approved this person before the
            // independent mailbox-verification invitation completed.
            return;
        }
        if ($current) {
            if ($current->starts_on > $today) {
                throw new \RuntimeException('Cannot replace a future director appointment');
            }
            DB::table('institution_director_assignments')->where('id', $current->id)->update([
                'ended_on' => $today, 'ended_by' => $invite->invited_by, 'updated_at' => now(),
            ]);
        }
        DB::table('institution_director_assignments')->insert([
            'school_id' => $school->id, 'director_id' => $profileId,
            'starts_on' => $today, 'ended_on' => null,
            'appointed_by' => $invite->invited_by, 'ended_by' => null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }
}
