<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

class ChildAccess
{
    public static function allowed($user, int $childId): bool
    {
        if (!$user || $childId <= 0) {
            return false;
        }

        if (in_array($user->role, ['admin', 'ministry'], true)) {
            return true;
        }

        if ($user->role === 'specialist') {
            return DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
        }

        if ($user->role === 'teacher') {
            return DB::table('children')
                    ->where('id', $childId)
                    ->where('assigned_teacher_id', $user->id)
                    ->exists()
                || DB::table('child_teacher')
                    ->where('child_id', $childId)
                    ->where('teacher_id', $user->id)
                    ->exists();
        }

        return $user->role === 'parent'
            && DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists();
    }
}
