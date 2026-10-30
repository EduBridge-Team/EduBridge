<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolContextController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'Forbidden'], 403);
        }

        // Never accept the school identifier or tenant from the client.
        // Personal directors receive access only through a live assignment.
        // Legacy school accounts retain their existing access path.
        if (($actor->role ?? null) === 'school') {
            $schools = DB::table('school_accounts as account')
                ->join('schools as school', 'school.id', '=', 'account.school_id')
                ->where('account.user_id', $actor->id)
                ->where('school.is_active', true)
                ->select('school.id', 'school.name', 'school.organization_id')
                ->limit(2)
                ->get();
        } else {
            $schools = DB::table('school_management_assignments as assignment')
                ->join('schools as school', 'school.id', '=', 'assignment.school_id')
                ->where('assignment.user_id', $actor->id)
                ->where('assignment.role', 'director')
                ->whereNull('assignment.ends_at')
                ->where('school.is_active', true)
                ->select('school.id', 'school.name', 'school.organization_id')
                ->limit(2)
                ->get();
        }

        if ($schools->count() !== 1) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }

        $school = $schools->first();
        if ($school->organization_id !== null) {
            $active = DB::table('organizations')
                ->where('id', $school->organization_id)
                ->where('is_active', true)
                ->exists();
            if (!$active) {
                return response()->json(['error' => 'School access is unavailable'], 403);
            }
        }

        return response()->json([
            'school' => [
                'id' => (int) $school->id,
                'name' => $school->name,
                'organization_id' => $school->organization_id === null
                    ? null : (int) $school->organization_id,
            ],
        ]);
    }
}
