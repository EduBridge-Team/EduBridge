<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait ConversationAccess
{
    private function conversationForUser(int $conversationId, int $userId): ?object
    {
        return DB::table('conversations')
            ->where('id', $conversationId)
            ->where(function ($query) use ($userId) {
                $query->where('participant_one_id', $userId)
                    ->orWhere('participant_two_id', $userId);
            })
            ->first();
    }

    private function canCommunicate(string $fromRole, string $toRole): bool
    {
        if ($fromRole === 'parent') {
            return in_array($toRole, ['teacher', 'specialist', 'admin'], true);
        }
        if ($toRole === 'parent') {
            return in_array($fromRole, ['teacher', 'specialist', 'admin'], true);
        }

        return in_array($fromRole, self::STAFF_ROLES, true)
            && in_array($toRole, self::STAFF_ROLES, true);
    }
}
