<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $base = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('users as tu', 'tu.id', '=', 'c.assigned_teacher_id')
                ->select('c.*', 'dt.name as disability_name', 'tu.name as assigned_teacher_name')
                ->orderBy('c.name');

            if ($user->role === 'parent') {
                $children = (clone $base)
                    ->join('child_parent as cp', 'cp.child_id', '=', 'c.id')
                    ->where('cp.parent_id', $user->id)
                    ->get();
            } else {
                if ($user->role === 'teacher') {
                    $base->where(function ($query) use ($user) {
                        $query->where('c.assigned_teacher_id', $user->id)->orWhereExists(function ($team) use ($user) {
                            $team->selectRaw('1')->from('child_teacher as ct')
                                ->whereColumn('ct.child_id', 'c.id')->where('ct.teacher_id', $user->id);
                        });
                    });
                } elseif (!in_array($user->role, ['admin', 'ministry', 'specialist'], true)) {
                    // Institution membership is not yet modelled: do not expose other institutions' children.
                    $base->whereRaw('1 = 0');
                }
                $children = $base->get();
            }

            if ($user->role === 'specialist') {
                $assignedIds = DB::table('child_specialist')->where('specialist_id', $user->id)->pluck('child_id')->map(fn ($id) => (int) $id)->all();
                $children = $children->map(function ($child) use ($assignedIds) {
                    if (in_array((int) $child->id, $assignedIds, true)) return $child;
                    // Keep the requested all-children discovery list without exposing private learning records.
                    return (object) array_intersect_key((array) $child, array_flip([
                        'id', 'name', 'age', 'status', 'disability_type_id', 'disability_type', 'disability_name',
                        'assigned_teacher_id', 'assigned_teacher_name',
                    ]));
                });
            }

            $children = $children->map(
                fn ($child) => $this->hideIdentityFieldsForStaff(
                    ($user->role === 'specialist' && !in_array((int) $child->id, $assignedIds ?? [], true)) ? $this->attachSpecialists($child) : $this->attachCurrentPlan(
                        $this->attachSpecialists($this->decodeChild($child))
                    ),
                    $user
                )
            );

            return response()->json(['children' => $children]);
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
