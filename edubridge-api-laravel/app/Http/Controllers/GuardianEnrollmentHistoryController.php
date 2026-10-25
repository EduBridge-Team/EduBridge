<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GuardianEnrollmentHistoryController extends Controller
{
    public function index(Request $request, int $child): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || $actor->role !== 'parent') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        if (!DB::table('child_parent')->where('child_id', $child)
            ->where('parent_id', $actor->id)->exists()) {
            return response()->json(['error' => 'Child unavailable'], 404);
        }

        $requests = DB::table('school_enrollment_requests as r')
            ->join('schools as s', 's.id', '=', 'r.school_id')
            ->join('children as c', 'c.id', '=', 'r.child_id')
            ->where('r.child_id', $child)
            ->select('r.id', 'r.school_id', 's.name as school_name',
                'r.child_id', 'c.name as child_name', 'r.status',
                'r.version', 'r.reason', 'r.created_at')
            ->orderByDesc('r.created_at')->orderByDesc('r.id')->get();

        $enrollment = DB::table('student_enrollments as e')
            ->join('sections as s', 's.id', '=', 'e.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('schools as school', 'school.id', '=', 'g.school_id')
            ->where('e.child_id', $child)->where('e.status', 'active')
            ->select('e.id', 'school.id as school_id', 'school.name as school_name',
                'e.child_id', 'e.section_id', 'e.status')->first();

        return response()->json([
            'child_id' => $child,
            'requests' => $requests,
            'active_enrollment' => $enrollment,
        ]);
    }
}
