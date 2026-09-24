<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait LearningSupportRequestHelpers
{
    private function requestQuery()
    {
        return DB::table('learning_support_requests as tr')
            ->join('children as c', 'c.id', '=', 'tr.child_id')
            ->join('users as p', 'p.id', '=', 'tr.parent_id')
            ->leftJoin('users as s', 's.id', '=', 'tr.specialist_id')
            ->select(
                'tr.*',
                'c.name as child_name',
                'p.name as parent_name',
                's.name as specialist_name'
            );
    }
    
    private function parentOwnsChild(int $parentId, int $childId): bool
    {
        return DB::table('child_parent')
            ->where('parent_id', $parentId)
            ->where('child_id', $childId)
            ->exists();
    }
    
    private function canViewChild($user, int $childId): bool
    {
        if (!$user) {
            return false;
        }
    
        if (in_array($user->role, ['specialist', 'admin'], true)) {
            return true;
        }
    
        return $user->role === 'parent'
            && $this->parentOwnsChild((int) $user->id, $childId);
    }
    
    // ولي الأمر ينشئ طلب جلسة دعم تعليمي لطفل مرتبط بحسابه.
    private function upsertSessionForRequest($learningSupportRequest, int $specialistId, $scheduledAt, string $meetingLink, ?string $notes): void
    {
        $payload = [
            'specialist_id' => $specialistId,
            'child_id' => $learningSupportRequest->child_id,
            'learning_support_request_id' => $learningSupportRequest->id,
            'type' => 'learningPlanning',
            'scheduled_at' => $scheduledAt,
            'duration_minutes' => 45,
            'meeting_link' => $meetingLink,
            'notes' => $notes,
            'status' => 'scheduled',
        ];
    
        $existingId = DB::table('sessions')
            ->where('learning_support_request_id', $learningSupportRequest->id)
            ->value('id');
    
        if ($existingId) {
            DB::table('sessions')->where('id', $existingId)->update($payload);
        } else {
            DB::table('sessions')->insert($payload);
        }
    }
    
    // المختص يحدد الموعد ورابط الاجتماع، ويصبح هو المختص المسؤول عن الطلب.
}
