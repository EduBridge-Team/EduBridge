<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait CaseDiscussionControllerHelpers
{
    private function canAccessChild($user, int $childId): bool
    {
        if (!$user) return false;
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
        if (!$user || !$discussion) return false;
        if ($user->role === 'admin') return true;
        if ((int) $discussion->created_by_id === (int) $user->id) return true;
    
        return DB::table('case_discussion_participants')
            ->where('discussion_id', $discussion->id)
            ->where('user_id', $user->id)
            ->exists();
    }
    
    private function participantRows(int $discussionId)
    {
        return DB::table('case_discussion_participants as p')
            ->join('users as u', 'u.id', '=', 'p.user_id')
            ->where('p.discussion_id', $discussionId)
            ->select('u.id as user_id','u.name','u.role','u.specialty')
            ->orderBy('u.name')
            ->get();
    }
    
    private function messageRows(int $discussionId)
    {
        return DB::table('case_discussion_messages as m')
            ->join('users as u', 'u.id', '=', 'm.sender_id')
            ->where('m.discussion_id', $discussionId)
            ->select(
                'm.id',
                'm.discussion_id',
                'm.sender_id',
                'u.name as sender_name',
                'u.role as sender_role',
                'm.content',
                'm.type',
                'm.attachments',
                'm.created_at'
            )
            ->orderBy('m.created_at')
            ->get()
            ->map(function ($m) {
                $m->attachments = is_string($m->attachments)
                    ? (json_decode($m->attachments, true) ?: [])
                    : ($m->attachments ?: []);
                return $m;
            });
    }
    
    private function hydrate($row): array
    {
        $data = (array) $row;
        $data['child_avatar'] = '🧒';
        $data['participants'] = $this->participantRows((int) $row->id);
        $data['messages'] = $this->messageRows((int) $row->id);
        $data['unread_count'] = 0;
        return $data;
    }
    
    private function baseQuery()
    {
        return DB::table('case_discussions as d')
            ->join('children as c', 'c.id', '=', 'd.child_id')
            ->join('users as cb', 'cb.id', '=', 'd.created_by_id')
            ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
            ->select(
                'd.*',
                'c.name as child_name',
                'dt.name as disability_type',
                'cb.name as created_by_name'
            );
    }
    
}
