<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait SessionControllerHelpers
{
    private function baseQuery()
    {
        return DB::table('sessions as s')
            ->join('children as c', 'c.id', '=', 's.child_id')
            ->leftJoin('users as u', 'u.id', '=', 's.specialist_id')
            ->select('s.*', 'c.name as child_name', 'u.name as specialist_name')
            ->orderByDesc('s.scheduled_at');
    }
    
    private function normalizeSession($session): array
    {
        $data = (array) $session;
        $data['status'] = ($data['status'] ?? 'scheduled') === 'done'
            ? 'completed'
            : ($data['status'] ?? 'scheduled');
    
        $tags = $data['tags'] ?? [];
        if (is_string($tags)) {
            $decoded = json_decode($tags, true);
            $tags = is_array($decoded) ? $decoded : [];
        }
        $data['tags'] = is_array($tags) ? array_values($tags) : [];
        $legacyTypes = [
            'initial' => 'learningPlanning',
            'crisis' => 'teamReview',
            'family' => 'parentReview',
            'group' => 'groupSupport',
        ];
        $rawType = $data['type'] ?? 'followUp';
        $data['type'] = $legacyTypes[$rawType] ?? $rawType;
        $data['duration_minutes'] = (int) ($data['duration_minutes'] ?? 45);
    
        return $data;
    }
    
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
        if ($user->role === 'parent') {
            return DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists();
        }
    
        return false;
    }
    
    private function canAccess($user, $session): bool
    {
        if (!$user || !$session) {
            return false;
        }
        if ($user->role === 'admin') {
            return true;
        }
        if ($user->role === 'specialist') {
            return (int) $session->specialist_id === (int) $user->id;
        }
        if ($user->role === 'teacher') {
            return $this->canAccessChild($user, (int) $session->child_id);
        }
        if ($user->role === 'parent') {
            return DB::table('child_parent')
                ->where('child_id', $session->child_id)
                ->where('parent_id', $user->id)
                ->exists();
        }
    
        return false;
    }
    
    // GET /api/sessions and /api/learning-support/meetings
}
