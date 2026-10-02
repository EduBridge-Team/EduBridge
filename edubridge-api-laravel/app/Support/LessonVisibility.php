<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

final class LessonVisibility
{
    public static function scope($query, object $user, string $prefix = '')
    {
        if ($user->role === 'admin') {
            return $query;
        }
        $children = match ($user->role) {
            'parent' => DB::table('child_parent')->where('parent_id', $user->id)->pluck('child_id'),
            'specialist' => DB::table('child_specialist')->where('specialist_id', $user->id)->pluck('child_id'),
            'teacher' => DB::table('children')->where('assigned_teacher_id', $user->id)->pluck('id')
                ->merge(DB::table('child_teacher')->where('teacher_id', $user->id)->pluck('child_id'))->unique(),
            'ministry' => DB::table('children')->pluck('id'),
            default => collect(),
        };

        return $query->where(function ($allowed) use ($user, $prefix, $children) {
            $allowed->where($prefix . 'teacher_id', $user->id)
                ->orWhereNull($prefix . 'target_type')
                ->orWhere($prefix . 'target_type', '!=', 'specificChildren');
            foreach ($children as $id) {
                $allowed->orWhere(function ($targeted) use ($id, $prefix) {
                    $targeted->where($prefix . 'target_type', 'specificChildren')
                        ->whereJsonContains($prefix . 'target_child_ids', (int) $id);
                });
            }
        });
    }

    public static function allowed(object $user, int $lessonId): bool
    {
        $lesson = DB::table('lessons')->find($lessonId);
        if (!$lesson) return false;
        if ($user->role === 'admin' || (int) ($lesson->teacher_id ?? 0) === (int) $user->id
            || ($lesson->target_type ?? null) !== 'specificChildren') return true;
        $ids = is_string($lesson->target_child_ids ?? null)
            ? json_decode($lesson->target_child_ids, true) : ($lesson->target_child_ids ?? []);
        foreach (is_array($ids) ? $ids : [] as $childId) {
            if (ChildAccess::allowed($user, (int) $childId)) return true;
        }
        return false;
    }
}
