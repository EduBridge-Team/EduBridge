<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait ChildAccessibilityProfileHelpers
{
    private function canAccessChild(int $userId, string $role, int $childId): bool
    {
        if ($role === 'admin') {
            return DB::table('children')->where('id', $childId)->exists();
        }

        if ($role === 'teacher') {
            return DB::table('children')
                ->where('id', $childId)
                ->where('assigned_teacher_id', $userId)
                ->exists()
                || DB::table('child_teacher')
                    ->where('child_id', $childId)
                    ->where('teacher_id', $userId)
                    ->exists();
        }

        if ($role === 'specialist') {
            return DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $userId)
                ->exists();
        }

        if ($role === 'parent') {
            return DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $userId)
                ->exists();
        }

        return false;
    }
}
