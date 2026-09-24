<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait ConsultationAccess
{
    private function canAccessChild($user, int $childId): bool
    {
        if (!$user) {
            return false;
        }
        if ($user->role === 'admin') {
            return DB::table('children')->where('id', $childId)->exists();
        }
        if ($user->role === 'parent') {
            return DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
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

        return false;
    }

    private function canAccess($user, $consultation): bool
    {
        if (in_array($user->role, ['admin', 'specialist'], true)) {
            if ($user->role === 'specialist') {
                return (int) ($consultation->specialist_id ?? 0) === (int) $user->id
                    || ($consultation->specialist_id === null && ($consultation->status ?? null) === 'open');
            }
            return true;
        }
        if ((int) $consultation->requester_id === (int) $user->id) {
            return true;
        }

        return DB::table('child_parent')
            ->where('child_id', $consultation->child_id)
            ->where('parent_id', $user->id)
            ->exists();
    }
}
