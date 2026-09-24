<?php

namespace App\Http\Controllers\Concerns;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

trait LearningSupportMeetingScheduleHelpers
{
    private function parseScheduledAt(string $scheduledRaw)
    {
        try {
            return Carbon::parse($scheduledRaw);
        } catch (\Throwable $e) {
            return null;
        }
    }

    private function resolveAssignedSpecialistId($user, $request, $learningSupportRequest): int
    {
        if ($user->role === 'specialist') {
            return (int) $user->id;
        }

        return (int) (
            $request->input('specialist_id')
            ?: ($learningSupportRequest->specialist_id ?: 0)
        );
    }

    private function validSpecialist(int $specialistId): bool
    {
        return $specialistId > 0
            && DB::table('users')
                ->where('id', $specialistId)
                ->where('role', 'specialist')
                ->exists();
    }
}
