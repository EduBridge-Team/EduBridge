<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolEnrollmentInboxController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'Forbidden'], 403);
        }

        $school = \App\Support\SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'School unavailable'], 403);
        $schoolId = (int) $school->id;
        $requests = DB::table('school_enrollment_requests as r')
            ->join('children as c', 'c.id', '=', 'r.child_id')
            ->join('schools as s', 's.id', '=', 'r.school_id')
            ->where('r.school_id', $schoolId)->where('r.status', 'pending')
            ->select('r.id', 'r.school_id', 's.name as school_name',
                'r.child_id', 'c.name as child_name', 'r.status', 'r.version',
                'r.reason', 'r.created_at')
            ->orderBy('r.created_at')->orderBy('r.id')->limit(200)->get();

        return response()->json(['school_id' => $schoolId, 'requests' => $requests]);
    }
}
