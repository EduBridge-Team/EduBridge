<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait HomeworkAccessHelpers
{
    private function canViewChild($user, int $childId): bool
    {
        if (!$user) {
            return false;
        }

        if ($user->role === 'student') {
            return DB::table('student_account_links as link')
                ->join('school_internal_identities as identity', function ($join) {
                    $join->on('identity.user_id', '=', 'link.user_id')
                        ->on('identity.school_id', '=', 'link.school_id');
                })
                ->join('schools as school', 'school.id', '=', 'link.school_id')
                ->join('student_enrollments as enrollment', 'enrollment.child_id', '=', 'link.child_id')
                ->join('sections as section', 'section.id', '=', 'enrollment.section_id')
                ->join('grades as grade', 'grade.id', '=', 'section.grade_id')
                ->where('link.user_id', $user->id)
                ->where('link.child_id', $childId)
                ->whereColumn('grade.school_id', 'link.school_id')
                ->where('enrollment.status', 'active')
                ->where('school.is_active', true)
                ->where('identity.is_active', true)
                ->exists();
        }

        if ($user->role === 'admin') {
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
