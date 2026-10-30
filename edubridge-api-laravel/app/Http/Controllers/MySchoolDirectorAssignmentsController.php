<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MySchoolDirectorAssignmentsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'Forbidden'], 403);
        }

        // Read-only discovery. This endpoint does not grant school permissions.
        // Only active assignments for the authenticated user are returned.
        $schools = DB::table('school_management_assignments as assignment')
            ->join('schools as school', 'school.id', '=', 'assignment.school_id')
            ->leftJoin('organizations as organization', 'organization.id', '=', 'school.organization_id')
            ->where('assignment.user_id', $actor->id)
            ->where('assignment.role', 'director')
            ->whereNull('assignment.ends_at')
            ->where('school.is_active', true)
            ->where(function ($query) {
                $query->whereNull('school.organization_id')
                    ->orWhere('organization.is_active', true);
            })
            ->select('school.id', 'school.name', 'school.organization_id',
                'school.internal_domain', 'school.internal_domain_confirmed_at',
                'assignment.starts_at')
            ->orderBy('school.id')
            ->get();

        return response()->json(['schools' => $schools]);
    }
}
