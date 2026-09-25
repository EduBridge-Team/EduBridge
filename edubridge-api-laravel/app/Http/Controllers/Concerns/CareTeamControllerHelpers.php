<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait CareTeamControllerHelpers
{
    private function canView($user, int $childId): bool
    {
        if (!$user) return false;
        if ($user->role === 'admin') return true;
    
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
    
        return $user->role === 'parent'
            && DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists();
    }
    
    private function canManage($user, int $childId): bool
    {
        if (!$user) return false;
        if ($user->role === 'admin') return true;
    
        return $user->role === 'specialist'
            && DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
    }
    
    private function teachers(int $childId)
    {
        return DB::table('child_teacher as ct')
            ->join('users as u', 'u.id', '=', 'ct.teacher_id')
            ->where('ct.child_id', $childId)
            ->select(
                'u.id',
                'u.id as user_id',
                'u.name',
                'u.email',
                DB::raw("'teacher' as role"),
                'ct.subject',
                'ct.assigned_at'
            )
            ->orderBy('u.name')
            ->get();
    }
    
    private function specialists(int $childId)
    {
        return DB::table('child_specialist as cs')
            ->join('users as u', 'u.id', '=', 'cs.specialist_id')
            ->where('cs.child_id', $childId)
            ->select(
                'u.id',
                'u.id as user_id',
                'u.name',
                'u.email',
                DB::raw("'specialist' as role"),
                'cs.specialty',
                'cs.assigned_at'
            )
            ->orderBy('u.name')
            ->get();
    }
    
}
