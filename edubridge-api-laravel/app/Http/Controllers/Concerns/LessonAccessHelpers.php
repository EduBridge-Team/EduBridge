<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait LessonAccessHelpers
{
    private function canTargetChildren($user, array $childIds): bool
    {
        if (!$user || !$childIds) {
            return false;
        }

        $childIds = array_values(array_unique(array_map('intval', $childIds)));
        if (DB::table('children')->whereIn('id', $childIds)->count() !== count($childIds)) {
            return false;
        }

        if (($user->role ?? null) === 'admin') {
            return true;
        }

        if (($user->role ?? null) === 'teacher') {
            $primary = DB::table('children')
                ->whereIn('id', $childIds)
                ->where('assigned_teacher_id', $user->id)
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->all();

            $team = DB::table('child_teacher')
                ->whereIn('child_id', $childIds)
                ->where('teacher_id', $user->id)
                ->pluck('child_id')
                ->map(fn ($id) => (int) $id)
                ->all();

            return count(array_unique(array_merge($primary, $team))) === count($childIds);
        }

        if (($user->role ?? null) === 'specialist') {
            return DB::table('child_specialist')
                ->whereIn('child_id', $childIds)
                ->where('specialist_id', $user->id)
                ->distinct()
                ->count('child_id') === count($childIds);
        }

        return false;
    }

    private function canManageLesson($user, $lesson): bool
    {
        if (!$user) {
            return false;
        }

        if (($user->role ?? null) === 'admin') {
            return true;
        }

        return (int) ($lesson->teacher_id ?? 0) === (int) ($user->id ?? 0);
    }

    private function parseTargetChildIds($raw): array
    {
        if ($raw === null || $raw === '') {
            return [];
        }

        if (is_string($raw)) {
            $decoded = json_decode($raw, true);
            $raw = is_array($decoded) ? $decoded : [];
        }

        if (!is_array($raw)) {
            return [];
        }

        return array_values(array_unique(array_filter(
            array_map('intval', $raw),
            fn ($id) => $id > 0
        )));
    }
}
