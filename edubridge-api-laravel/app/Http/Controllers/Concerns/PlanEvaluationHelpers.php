<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait PlanEvaluationHelpers
{
    private function canEvaluatePlan($user, int $childId): bool
    {
        if (($user->role ?? null) === 'admin') {
            return true;
        }

        return ($user->role ?? null) === 'specialist'
            && DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
    }
}
