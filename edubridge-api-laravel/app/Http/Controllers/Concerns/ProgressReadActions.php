<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait ProgressReadActions
{
    public function byChild($childId)
    {
        try {
            $progress = DB::table('progress as p')
                ->join('lessons as l', 'l.id', '=', 'p.lesson_id')
                ->where('p.child_id', $childId)
                ->orderByRaw('p.completed_at DESC NULLS LAST')
                ->select(
                    'p.id',
                    'p.status',
                    'p.score',
                    'p.completed_at',
                    'l.id as lesson_id',
                    'l.title as lesson_title'
                )
                ->get();

            return response()->json(['progress' => $progress]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function summary($childId)
    {
        try {
            $summary = DB::table('progress')
                ->where('child_id', $childId)
                ->selectRaw("
                    COUNT(*) FILTER (WHERE status = 'done') AS done,
                    COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress,
                    COUNT(*) FILTER (WHERE status = 'not_started') AS not_started,
                    ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int AS avg_score
                ")
                ->first();

            return response()->json(['summary' => $summary]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
