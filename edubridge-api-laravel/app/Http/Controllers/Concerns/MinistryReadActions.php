<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait MinistryReadActions
{
    public function lessons(Request $request)
    {
        try {
            $query = DB::table('lessons as l')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'l.disability_type_id')
                ->leftJoin('users as t', 't.id', '=', 'l.teacher_id')
                ->select('l.*', 'dt.name as disability_name', 't.name as teacher_name')
                ->orderByDesc('l.created_at');

            $status = $request->query('status');
            if ($status && in_array($status, ['pending', 'approved', 'rejected'], true)) {
                $query->where('l.curriculum_status', $status);
            }
            if ($request->query('education_level')) {
                $query->where('l.education_level', $request->query('education_level'));
            }

            return response()->json(['lessons' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function users(Request $request)
    {
        try {
            $users = DB::table('users')
                ->select(
                    'id',
                    'name',
                    'email',
                    'role',
                    'phone',
                    'verification_status',
                    'created_at'
                )
                ->orderBy('name')
                ->get();

            return response()->json(['users' => $users]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function children()
    {
        try {
            $children = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('users as tu', 'tu.id', '=', 'c.assigned_teacher_id')
                ->select(
                    'c.id',
                    'c.name',
                    'c.age',
                    'c.status',
                    'c.assigned_teacher_id',
                    'c.disability_type',
                    'dt.name as disability_name',
                    'tu.name as assigned_teacher_name'
                )
                ->orderBy('c.name')
                ->get()
                ->map(function ($child) {
                    if (empty($child->disability_type) && !empty($child->disability_name)) {
                        $child->disability_type = $child->disability_name;
                    }

                    return $child;
                });

            return response()->json(['children' => $children]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
