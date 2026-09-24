<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait EvaluationReadActions
{
    public function byChild($childId)
    {
        try {
            $evaluations = DB::table('evaluations as e')
                ->leftJoin('users as u', 'u.id', '=', 'e.evaluator_id')
                ->where('e.child_id', $childId)
                ->orderByDesc('e.created_at')
                ->select('e.*', 'u.name as evaluator_name')
                ->get()
                ->map(fn ($evaluation) => $this->decode($evaluation));

            return response()->json(['evaluations' => $evaluations]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
