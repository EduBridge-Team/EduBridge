<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait MinistryApprovalHelpers
{
    private function canAccessChild($user, int $childId): bool
    {
        if (!$user) {
            return false;
        }

        if (in_array($user->role, ['admin', 'ministry'], true)) {
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

        if ($user->role === 'specialist') {
            return DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
        }

        return false;
    }

    private function query()
    {
        return DB::table('ministry_approvals as a')
            ->join('children as c', 'c.id', '=', 'a.child_id')
            ->leftJoin('users as s', 's.id', '=', 'a.submitted_by')
            ->leftJoin('users as t', 't.id', '=', 'a.teacher_id')
            ->select(
                'a.*',
                'c.name as child_name',
                's.name as submitted_by_name',
                't.name as teacher_name'
            )
            ->orderByDesc('a.created_at');
    }

    private function normalize($row): array
    {
        $data = (array) $row;
        $methods = $data['teaching_methods'] ?? [];
        if (is_string($methods)) {
            $decoded = json_decode($methods, true);
            $methods = is_array($decoded) ? $decoded : [];
        }
        $data['teaching_methods'] = array_values(is_array($methods) ? $methods : []);

        return $data;
    }
}
