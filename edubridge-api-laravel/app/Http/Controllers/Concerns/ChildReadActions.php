<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use App\Support\ListPage;
use Illuminate\Support\Facades\DB;

trait ChildReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $paging = ListPage::parameters($request);

        try {
            $base = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('users as tu', 'tu.id', '=', 'c.assigned_teacher_id')
                ->select('c.*', 'dt.name as disability_name', 'tu.name as assigned_teacher_name')
                ->orderBy('c.name');

            if ($user->role === 'parent') {
                $base->whereExists(function ($parents) use ($user) {
                    $parents->selectRaw('1')->from('child_parent as cp')
                        ->whereColumn('cp.child_id', 'c.id')->where('cp.parent_id', $user->id);
                });
            } elseif ($user->role === 'teacher') {
                $base->where(function ($query) use ($user) {
                    $query->where('c.assigned_teacher_id', $user->id)->orWhereExists(function ($team) use ($user) {
                        $team->selectRaw('1')->from('child_teacher as ct')
                            ->whereColumn('ct.child_id', 'c.id')->where('ct.teacher_id', $user->id);
                    });
                });
            } elseif (!in_array($user->role, ['admin', 'ministry', 'specialist'], true)) {
                $base->whereRaw('1 = 0');
            }

            $summary = null;
            if ($paging !== null) {
                if ($user->role === 'parent') {
                    $stats = (clone $base)->reorder()->select([])->selectRaw("COUNT(*) as total_children, COALESCE(SUM(CASE WHEN c.status IN ('assigned', 'evaluated') THEN 1 ELSE 0 END), 0) as active_plans")->first();
                    $done = DB::table('progress')->where('status', 'done')
                        ->whereIn('child_id', (clone $base)->reorder()->select('c.id'))->count();
                    $summary = ['total_children' => (int) $stats->total_children, 'active_plans' => (int) $stats->active_plans, 'completed_tasks' => $done];
                }
                if (trim((string) ($paging['q'] ?? '')) !== '') {
                    ListPage::search($base, $paging['q'], ['c.name', 'tu.name', 'dt.name', 'c.disability_type']);
                }
                if ($paging['active_only'] ?? false) $base->whereIn('c.status', ['assigned', 'evaluated']);
                if ($user->role === 'specialist' && ($paging['assigned_only'] ?? false)) {
                    $base->whereExists(function ($assigned) use ($user) {
                        $assigned->selectRaw('1')->from('child_specialist as cs')
                            ->whereColumn('cs.child_id', 'c.id')->where('cs.specialist_id', $user->id);
                    });
                }
                $page = $base->orderBy('c.id')->paginate($paging['per_page'], ['*'], 'page', $paging['page']);
                $children = collect($page->items());
            } else {
                $children = $base->orderBy('c.id')->get();
            }

            if ($user->role === 'specialist') {
                $assignedIds = DB::table('child_specialist')->where('specialist_id', $user->id)->whereIn('child_id', $children->pluck('id'))->pluck('child_id')->map(fn ($id) => (int) $id)->all();
                $children = $children->map(function ($child) use ($assignedIds) {
                    if (in_array((int) $child->id, $assignedIds, true)) return $child;
                    // Keep the requested all-children discovery list without exposing private learning records.
                    return (object) array_intersect_key((array) $child, array_flip([
                        'id', 'name', 'age', 'status', 'disability_type_id', 'disability_type', 'disability_name',
                        'assigned_teacher_id', 'assigned_teacher_name',
                    ]));
                });
            }

            $planChildIds = $children->filter(fn ($child) => $user->role !== 'specialist'
                || in_array((int) $child->id, $assignedIds ?? [], true))->pluck('id');
            [$specialists, $plans] = $this->loadChildRelations($children, $planChildIds);
            $children = $children->map(function ($child) use ($user, $specialists, $plans, $planChildIds) {
                $summaryOnly = $user->role === 'specialist'
                    && !$planChildIds->contains($child->id);
                $child = $this->attachSpecialists($summaryOnly ? $child : $this->decodeChild($child), $specialists);
                if (!$summaryOnly) {
                    $child = $this->attachCurrentPlan($child, $plans);
                }
                return $this->hideIdentityFieldsForStaff($child, $user);
            });

            return response()->json(['children' => $children->values()]
                + ($paging !== null ? ['pagination' => ListPage::metadata($page)] : [])
                + ($summary !== null ? ['summary' => $summary] : []));
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function show(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $child = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('users as tu', 'tu.id', '=', 'c.assigned_teacher_id')
                ->leftJoin('organizations as o', 'o.id', '=', 'c.organization_id')
                ->where('c.id', $id)
                ->select('c.*', 'dt.name as disability_name', 'tu.name as assigned_teacher_name', 'o.name as organization_name')
                ->first();

            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            $child = $this->hideIdentityFieldsForStaff(
                $this->attachCurrentPlan(
                    $this->attachSpecialists($this->decodeChild($child))
                ),
                $user
            );

            return response()->json(['child' => $child]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
