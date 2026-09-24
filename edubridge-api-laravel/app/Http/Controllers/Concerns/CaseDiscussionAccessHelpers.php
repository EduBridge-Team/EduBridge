<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait CaseDiscussionAccessHelpers
{
    private function canAccessChild($user, int $childId): bool
    {
        if (!$user) {
            return false;
        }

        if ($user->role === 'admin') {
            return DB::table('children')->where('id', $childId)->exists();
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

        if ($user->role === 'specialist') {
            return DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
        }

        return false;
    }

    private function careTeamUserIds(int $childId): array
    {
        $ids = DB::table('child_teacher')
            ->where('child_id', $childId)
            ->pluck('teacher_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        $primaryTeacherId = DB::table('children')
            ->where('id', $childId)
            ->value('assigned_teacher_id');

        if ($primaryTeacherId) {
            $ids[] = (int) $primaryTeacherId;
        }

        $ids = array_merge(
            $ids,
            DB::table('child_specialist')
                ->where('child_id', $childId)
                ->pluck('specialist_id')
                ->map(fn ($id) => (int) $id)
                ->all()
        );

        return array_values(array_unique($ids));
    }

    private function canAccess($user, $discussion): bool
    {
        if (!$user || !$discussion) {
            return false;
        }

        if ($user->role === 'admin') {
            return true;
        }

        if ((int) $discussion->created_by_id === (int) $user->id) {
            return true;
        }

        return DB::table('case_discussion_participants')
            ->where('discussion_id', $discussion->id)
            ->where('user_id', $user->id)
            ->exists();
    }
}
