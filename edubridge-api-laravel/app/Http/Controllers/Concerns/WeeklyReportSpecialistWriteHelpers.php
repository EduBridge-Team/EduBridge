<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait WeeklyReportSpecialistWriteHelpers
{
    private function persistSpecialistWeeklyReport(
        $user,
        int $childId,
        $weekStart,
        $weekEnd,
        string $specialistNotes,
        string $recommendations
    ): array {
        $existing = DB::table('weekly_reports')
            ->where('child_id', $childId)
            ->whereDate('week_start', $weekStart->toDateString())
            ->first();

        if ($existing) {
            DB::table('weekly_reports')->where('id', $existing->id)->update([
                'specialist_notes' => $specialistNotes,
                'updated_at' => now(),
            ]);

            return ['id' => $existing->id, 'status' => 200];
        }

        $id = DB::table('weekly_reports')->insertGetId([
            'child_id' => $childId,
            'author_id' => $user->id,
            'week_start' => $weekStart,
            'week_end' => $weekEnd,
            'lessons_completed' => 0,
            'progress_percentage' => 0,
            'specialist_notes' => $specialistNotes,
            'achievements' => json_encode([], JSON_UNESCAPED_UNICODE),
            'concerns' => json_encode(
                $recommendations !== '' ? [$recommendations] : [],
                JSON_UNESCAPED_UNICODE
            ),
            'generated_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return ['id' => $id, 'status' => 201];
    }
}
