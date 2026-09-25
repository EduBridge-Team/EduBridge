<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait MinistryStatisticsActions
{
    public function stats()
    {
        try {
            return response()->json([
                'children_count' => DB::table('children')->count(),
                'users_count' => DB::table('users')->count(),
                'pending_approvals' => DB::table('lessons')->where('curriculum_status', 'pending')->count(),
                'schools_count' => DB::table('organizations')->count(),
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function statistics()
    {
        try {
            $byDisability = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->selectRaw("COALESCE(dt.name, 'غير محدد') as label, COUNT(*) as total")
                ->groupByRaw("COALESCE(dt.name, 'غير محدد')")
                ->pluck('total', 'label');

            $byAge = [
                '0-5' => DB::table('children')->whereBetween('age', [0, 5])->count(),
                '6-9' => DB::table('children')->whereBetween('age', [6, 9])->count(),
                '10-13' => DB::table('children')->whereBetween('age', [10, 13])->count(),
                '14+' => DB::table('children')->where('age', '>=', 14)->count(),
            ];

            $assignedTotal = 0;
            foreach (DB::table('homeworks')->get(['assigned_child_ids']) as $homework) {
                $ids = $homework->assigned_child_ids;
                if (is_string($ids)) {
                    $ids = json_decode($ids, true) ?: [];
                }
                if (is_array($ids)) {
                    $assignedTotal += count($ids);
                }
            }

            $submitted = DB::table('homework_submissions')->count();
            $homeworkRate = $assignedTotal > 0
                ? (int) round(($submitted / $assignedTotal) * 100)
                : 0;

            return response()->json([
                'total_children' => DB::table('children')->count(),
                'active_children' => DB::table('children')->whereIn('status', ['evaluated', 'assigned'])->count(),
                'homework_completion_rate' => min(100, $homeworkRate),
                'learning_support_meetings_count' => DB::table('sessions')->count(),
                'by_disability_type' => $byDisability,
                'by_age_group' => $byAge,
            ]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function progressStatistics()
    {
        try {
            $rows = DB::table('progress')
                ->selectRaw("COUNT(*) FILTER (WHERE status = 'done') as completed")
                ->selectRaw("COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress")
                ->selectRaw("COUNT(*) FILTER (WHERE status = 'not_started') as not_started")
                ->selectRaw("COALESCE(ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int, 0) as average_score")
                ->first();

            return response()->json([
                'completed' => (int) ($rows->completed ?? 0),
                'in_progress' => (int) ($rows->in_progress ?? 0),
                'not_started' => (int) ($rows->not_started ?? 0),
                'average_score' => (int) ($rows->average_score ?? 0),
            ]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
