<?php

namespace App\Http\Controllers\Concerns;

use Carbon\Carbon;
use Illuminate\Http\Request;
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

    private function scheduleInput(Request $request): array
    {
        return [
            'scheduled_raw' => trim((string) $request->input('scheduled_at', '')),
            'meeting_link' => trim((string) $request->input('meeting_link', '')),
            'notes' => trim((string) $request->input('specialist_notes', '')),
        ];
    }

    private function persistScheduledMeeting(
        $learningSupportRequest,
        int $assignedSpecialistId,
        $scheduledAt,
        string $meetingLink,
        string $notes
    ): void {
        DB::transaction(function () use (
            $learningSupportRequest,
            $assignedSpecialistId,
            $scheduledAt,
            $meetingLink,
            $notes
        ) {
            DB::table('learning_support_requests')->where('id', $learningSupportRequest->id)->update([
                'specialist_id' => $assignedSpecialistId,
                'scheduled_at' => $scheduledAt,
                'meeting_link' => $meetingLink,
                'specialist_notes' => $notes !== '' ? $notes : null,
                'status' => 'scheduled',
                'updated_at' => now(),
            ]);

            $this->upsertSessionForRequest(
                $learningSupportRequest,
                $assignedSpecialistId,
                $scheduledAt,
                $meetingLink,
                $notes !== '' ? $notes : null
            );
        });
    }
}
