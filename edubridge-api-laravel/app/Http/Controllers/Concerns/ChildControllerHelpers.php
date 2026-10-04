<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

trait ChildControllerHelpers
{
    private function validateDocumentUrl($user, ?string $url, ?string $current = null): bool
    {
        if ($url === null || $url === '') return true;
        if ($user && $user->role === 'admin') return true;
        if ($current !== null && $url === $current) return true;
        if (!$user) return false;

        $expectedPrefix = '/api/private-files/user/' . (int) $user->id . '/';
        return str_starts_with($url, $expectedPrefix);
    }

    private function decodeChild($child)
    {
        if (!$child) {
            return $child;
        }
        foreach (['strengths', 'challenges'] as $key) {
            if (isset($child->$key) && is_string($child->$key)) {
                $child->$key = json_decode($child->$key, true);
            }
        }
        unset($child->medical_history, $child->psychologist_notes);

        if (empty($child->disability_type) && !empty($child->disability_name)) {
            $child->disability_type = $child->disability_name;
        }
        return $child;
    }

    private function hideIdentityFieldsForStaff($child, $user)
    {
        if (!$child || !$user || in_array($user->role, ['admin', 'parent'], true)) {
            return $child;
        }

        $assignedSpecialist = false;
        if ($user->role === 'specialist' && !empty($child->id)) {
            $assignedSpecialist = DB::table('child_specialist')
                ->where('child_id', (int) $child->id)
                ->where('specialist_id', (int) $user->id)
                ->exists();
        }

        // Assigned specialists may read the child's approved identity and relationship
        // information needed for follow-up. Other staff roles never receive these fields.
        if (!$assignedSpecialist) {
            foreach ([
                'child_national_id',
                'guardian_national_id',
                'guardian_id_document_url',
                'kinship_document_url',
                'medical_report_url',
            ] as $field) {
                unset($child->$field);
            }
        }

        return $child;
    }

    private function loadChildRelations(Collection $children, Collection $planChildIds): array
    {
        $specialists = collect();
        $plans = collect();
        if ($children->isEmpty()) {
            return [$specialists, $plans];
        }

        try {
            $specialists = DB::table('child_specialist as cs')
                ->join('users as u', 'u.id', '=', 'cs.specialist_id')
                ->whereIn('cs.child_id', $children->pluck('id'))
                ->orderBy('cs.assigned_at')
                ->select('cs.child_id', 'u.id', 'u.name', 'cs.specialty', 'cs.assigned_at')
                ->get()->groupBy('child_id')
                ->map(fn ($items) => $items->map(function ($item) {
                    unset($item->child_id);
                    return $item;
                }));
        } catch (\Throwable $e) {
            report($e);
        }

        if ($planChildIds->isNotEmpty()) {
            try {
                $ranked = DB::table('ministry_approvals')
                    ->whereIn('child_id', $planChildIds)
                    ->where('status', 'approved')
                    ->select('*')
                    ->selectRaw('ROW_NUMBER() OVER (PARTITION BY child_id ORDER BY reviewed_at DESC, created_at DESC, id DESC) as plan_rank');
                $plans = DB::query()->fromSub($ranked, 'ranked_plans')
                    ->where('plan_rank', 1)->get()->keyBy('child_id');
            } catch (\Throwable $e) {
                report($e);
            }
        }

        return [$specialists, $plans];
    }

    private function attachCurrentPlan($child, ?Collection $loadedPlans = null)
    {
        if (!$child) {
            return $child;
        }

        try {
            $plan = $loadedPlans !== null ? $loadedPlans->get($child->id) : DB::table('ministry_approvals')
                ->where('child_id', $child->id)
                ->where('status', 'approved')
                ->orderByDesc('reviewed_at')
                ->orderByDesc('created_at')
                ->orderByDesc('id')
                ->first();

            $child->current_plan_id = $plan ? (int) $plan->id : null;
            $child->current_plan = $plan ? [
                'id' => (int) $plan->id,
                'educational_plan' => $plan->educational_plan ?? null,
                'teaching_methods' => is_string($plan->teaching_methods ?? null)
                    ? (json_decode($plan->teaching_methods, true) ?: [])
                    : ($plan->teaching_methods ?? []),
                'status' => $plan->status,
                'reviewed_at' => $plan->reviewed_at,
            ] : null;
        } catch (\Throwable $e) {
            report($e);
            $child->current_plan_id = null;
            $child->current_plan = null;
        }

        return $child;
    }

    private function attachSpecialists($child, ?Collection $loadedSpecialists = null)
    {
        if (!$child) {
            return $child;
        }

        try {
            $specialists = $loadedSpecialists !== null ? $loadedSpecialists->get($child->id, collect()) : DB::table('child_specialist as cs')
                ->join('users as u', 'u.id', '=', 'cs.specialist_id')
                ->where('cs.child_id', $child->id)
                ->orderBy('cs.assigned_at')
                ->select(
                    'u.id',
                    'u.name',
                    'cs.specialty',
                    'cs.assigned_at'
                )
                ->get();

            $child->specialists = $specialists;
            $child->specialist_ids = $specialists->pluck('id')->map(fn ($id) => (int) $id)->values()->all();
            $child->assigned_specialist_ids = $child->specialist_ids;

            if ($specialists->isNotEmpty()) {
                $first = $specialists->first();
                $child->specialist_id = (int) $first->id;
                $child->assigned_specialist_id = (int) $first->id;
                $child->specialist_name = $first->name;
            }
        } catch (\Throwable $e) {
            report($e);
            $child->specialists = [];
            $child->specialist_ids = [];
            $child->assigned_specialist_ids = [];
        }

        return $child;
    }
}
