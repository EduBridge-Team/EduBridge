<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SchoolInternalDomainController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $school = $this->authorizedSchool($request);
        if (!$school) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }

        return response()->json(['internal_domain' => $school->internal_domain,
            'confirmed_at' => $school->internal_domain_confirmed_at]);
    }

    public function confirm(Request $request): JsonResponse
    {
        $validation = Validator::make($request->all(), [
            'internal_domain' => ['required', 'string', 'regex:/^[a-z][a-z0-9-]{2,39}\\.edubridge$/'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }

        $domain = $validation->validated()['internal_domain'];
        try {
            return DB::transaction(function () use ($request, $domain) {
                $school = $this->authorizedSchool($request, true);
                if (!$school) {
                    return response()->json(['error' => 'School access is unavailable'], 403);
                }
                if ($school->internal_domain_confirmed_at !== null) {
                    return response()->json(['error' => 'Internal domain is immutable',
                        'internal_domain' => $school->internal_domain], 409);
                }
                DB::table('schools')->where('id', $school->id)
                    ->whereNull('internal_domain_confirmed_at')
                    ->update(['internal_domain' => $domain,
                        'internal_domain_confirmed_at' => now(), 'updated_at' => now()]);
                return response()->json(['internal_domain' => $domain, 'confirmed' => true]);
            }, 3);
        } catch (QueryException $e) {
            if (in_array((string) $e->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Internal domain is already taken'], 409);
            }
            throw $e;
        }
    }

    private function authorizedSchool(Request $request, bool $lock = false): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return null;
        }
        // Personal director accounts are authorized by a live assignment,
        // not by their global user role. Legacy school accounts remain supported.
        if (($actor->role ?? null) !== 'school') {
            $query = DB::table('school_management_assignments as assignment')
                ->join('schools as school', 'school.id', '=', 'assignment.school_id')
                ->where('assignment.user_id', $actor->id)
                ->where('assignment.role', 'director')
                ->whereNull('assignment.ends_at')
                ->where('school.is_active', true)
                ->select('school.id', 'school.organization_id', 'school.internal_domain',
                    'school.internal_domain_confirmed_at')
                ->limit(2);
            $schools = $lock ? $query->lockForUpdate()->get() : $query->get();
            if ($schools->count() !== 1) {
                return null;
            }
            $school = $schools->first();
            if ($school->organization_id !== null && !DB::table('organizations')
                ->where('id', $school->organization_id)->where('is_active', true)->exists()) {
                return null;
            }
            return $school;
        }
        $query = DB::table('school_accounts as account')
            ->join('schools as school', 'school.id', '=', 'account.school_id')
            ->where('account.user_id', $actor->id)
            ->where('school.is_active', true)
            ->select('school.id', 'school.organization_id', 'school.internal_domain',
                'school.internal_domain_confirmed_at')->limit(2);
        $schools = $lock ? $query->lockForUpdate()->get() : $query->get();
        if ($schools->count() !== 1) {
            return null;
        }
        $school = $schools->first();
        if ($school->organization_id !== null && !DB::table('organizations')
            ->where('id', $school->organization_id)->where('is_active', true)->exists()) {
            return null;
        }
        return $school;
    }
}
