<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolInternalIdentityDirectoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }

        $schools = DB::table('school_management_assignments as assignment')
            ->join('schools as school', 'school.id', '=', 'assignment.school_id')
            ->where('assignment.user_id', $actor->id)
            ->where('assignment.role', 'director')
            ->whereNull('assignment.ends_at')
            ->where('school.is_active', true)
            ->select('school.id', 'school.organization_id', 'school.internal_domain',
                'school.internal_domain_confirmed_at')
            ->limit(2)->get();
        if ($schools->count() !== 1) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }
        $school = $schools->first();
        if ($school->organization_id !== null && !DB::table('organizations')
            ->where('id', $school->organization_id)->where('is_active', true)->exists()) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }

        if ($school->internal_domain_confirmed_at === null) {
            return response()->json(['error' => 'School internal domain is not confirmed'], 409);
        }

        $identities = DB::table('school_internal_identities as identity')
            ->join('users as user', 'user.id', '=', 'identity.user_id')
            ->where('identity.school_id', $school->id)
            ->select('identity.id', 'identity.user_id', 'identity.username',
                'user.name', 'user.role')
            ->orderBy('identity.id')->limit(101)->get();
        return response()->json([
            'school_id' => (int) $school->id,
            'internal_domain' => $school->internal_domain,
            'identities' => $identities->take(100)->values(),
            'has_more' => $identities->count() > 100,
        ]);
    }
}
