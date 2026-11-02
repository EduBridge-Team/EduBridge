<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class SchoolDelegationController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'context');
        if (!$school) return response()->json(['error' => 'School access unavailable'], 403);
        if (($request->attributes->get('jwt_user')->role ?? null) === 'school'
            && ($school->official_email_verified_at ?? null) !== null) {
            // Official identity is not a director, and may not receive delegated writes.
            $director = DB::table('school_management_assignments as a')
                ->join('users as u', 'u.id', '=', 'a.user_id')
                ->where('a.school_id', $school->id)
                ->where('a.role', 'director')
                ->whereNull('a.ends_at')
                ->orderByDesc('a.id')
                ->first(['u.name']);
            return response()->json(['school' => [
                'id' => (int) $school->id,
                'name' => $school->name,
                'official_email' => $school->official_email,
                'official_email_verified' => $school->official_email_verified_at !== null,
                'is_active' => (bool) $school->is_active,
            ], 'director' => $director ? ['name' => $director->name] : null,
                'role' => 'school', 'permissions' => []]);
        }
        $deputy = ($school->management_role ?? null) === 'deputy_director';
        return response()->json(['school' => ['id' => (int) $school->id, 'name' => $school->name],
            'role' => $deputy ? 'deputy_director' : 'director',
            'permissions' => $deputy ? json_decode($school->delegated_permissions ?? '[]', true) : SchoolScopedAccess::PERMISSIONS]);
    }

    public function update(Request $request, int $assignment): JsonResponse
    {
        return DB::transaction(function () use ($request, $assignment) {
            $school = SchoolAdministration::directorSchool($request, true);
            if (!$school) return response()->json(['error' => 'Forbidden'], 403);
            $data = $request->validate(['permissions' => ['present', 'array', 'max:6'],
                'permissions.*' => ['required', 'string', 'distinct', Rule::in(SchoolScopedAccess::PERMISSIONS)]]);
            $count = DB::table('school_management_assignments')->where('id', $assignment)->where('school_id', $school->id)
                ->where('role', 'deputy_director')->whereNull('ends_at')->update(['permissions' => json_encode($data['permissions']), 'updated_at' => now()]);
            return response()->json(['updated' => (bool) $count, 'permissions' => $data['permissions']], $count ? 200 : 404);
        }, 3);
    }
}
