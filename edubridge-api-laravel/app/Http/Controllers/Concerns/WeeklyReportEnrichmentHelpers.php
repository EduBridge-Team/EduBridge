<?php

namespace App\Http\Controllers\Concerns;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

trait WeeklyReportEnrichmentHelpers
{
    private function enrich(array $data): array
    {
        $childId = (int) $data['child_id'];
        $weekStart = Carbon::parse($data['week_start'])->startOfDay();
        $weekEnd = Carbon::parse($data['week_end'])->endOfDay();

        $data['lessons_total'] = (int) DB::table('lessons')->count();
        if (!isset($data['lessons_completed']) || $data['lessons_completed'] === null) {
            $data['lessons_completed'] = (int) DB::table('progress')
                ->where('child_id', $childId)
                ->where('status', 'done')
                ->whereBetween('completed_at', [$weekStart, $weekEnd])
                ->count();
        }

        $homeworks = DB::table('homeworks')->get(['id', 'assigned_child_ids']);
        $assignedIds = [];
        foreach ($homeworks as $homework) {
            $ids = $homework->assigned_child_ids;
            if (is_string($ids)) {
                $ids = json_decode($ids, true) ?: [];
            }
            if (in_array($childId, array_map('intval', is_array($ids) ? $ids : []), true)) {
                $assignedIds[] = $homework->id;
            }
        }

        $data['homework_assigned'] = count($assignedIds);
        $data['homework_submitted'] = $assignedIds
            ? (int) DB::table('homework_submissions')
                ->where('child_id', $childId)
                ->whereIn('homework_id', $assignedIds)
                ->whereBetween('submitted_at', [$weekStart, $weekEnd])
                ->count()
            : 0;

        $data['learning_support_meetings_scheduled'] = (int) DB::table('sessions')
            ->where('child_id', $childId)
            ->whereBetween('scheduled_at', [$weekStart, $weekEnd])
            ->count();

        $data['learning_support_meetings_attended'] = (int) DB::table('sessions')
            ->where('child_id', $childId)
            ->whereBetween('scheduled_at', [$weekStart, $weekEnd])
            ->where('status', 'done')
            ->count();

        return $data;
    }
}
