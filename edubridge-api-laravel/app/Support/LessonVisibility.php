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
        // Keep assignment checks inside SQL. Large directories must not create
        // one PHP array entry and one OR clause for every authorized child.
        return $query->where(function ($allowed) use ($user, $prefix) {
            $allowed->where($prefix . 'teacher_id', $user->id)
                ->orWhereNull($prefix . 'target_type')
                ->orWhere($prefix . 'target_type', '!=', 'specificChildren');
            if (!in_array($user->role, ['parent', 'specialist', 'teacher', 'ministry'], true)) return;
            $allowed->orWhere(function ($targeted) use ($user, $prefix) {
                $targeted->where($prefix . 'target_type', 'specificChildren')
                    ->whereExists(function ($children) use ($user, $prefix) {
                        $children->selectRaw('1')->from('children as visible_child');
                        if (DB::getDriverName() === 'pgsql') {
                            $children->whereRaw("({$prefix}target_child_ids)::jsonb @> jsonb_build_array(visible_child.id)");
                        } else {
                            $children->whereRaw("EXISTS (SELECT 1 FROM json_each({$prefix}target_child_ids) AS target_ids WHERE target_ids.value = visible_child.id)");
                        }
                        if ($user->role === 'parent' || $user->role === 'specialist') {
                            $table = $user->role === 'parent' ? 'child_parent' : 'child_specialist';
                            $column = $user->role === 'parent' ? 'parent_id' : 'specialist_id';
                            $children->whereExists(function ($link) use ($user, $table, $column) {
                                $link->selectRaw('1')->from($table.' as visible_link')
                                    ->whereColumn('visible_link.child_id', 'visible_child.id')->where('visible_link.'.$column, $user->id);
                            });
                        } elseif ($user->role === 'teacher') {
                            $children->where(function ($team) use ($user) {
                                $team->where('visible_child.assigned_teacher_id', $user->id)->orWhereExists(function ($link) use ($user) {
                                    $link->selectRaw('1')->from('child_teacher as visible_team')
                                        ->whereColumn('visible_team.child_id', 'visible_child.id')->where('visible_team.teacher_id', $user->id);
                                });
                            });
                        }
                    });
            });
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
