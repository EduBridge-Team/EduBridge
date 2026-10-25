<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class GuardianSchoolRequestController extends Controller
{
    public function schools(Request $request): JsonResponse
    {
        if (($request->attributes->get('jwt_user')->role ?? null) !== 'parent') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $query = trim((string) $request->query('q', ''));
        if (mb_strlen($query) < 2 || mb_strlen($query) > 100) {
            return response()->json(['errors' => ['q' => ['Enter 2 to 100 characters.']]], 422);
        }
        $schools = DB::table('schools as s')
            ->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('s.is_active', true)
            ->where(function ($filter) {
                $filter->whereNull('s.organization_id')->orWhere('o.is_active', true);
            })
            ->whereRaw('LOWER(s.name) LIKE ?', ['%' . mb_strtolower($query) . '%'])
            ->select('s.id', 's.name', 's.address')
            ->orderBy('s.name')->limit(50)->get();
        return response()->json(['schools' => $schools]);
    }

    public function submit(Request $request, int $child): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || ($actor->role ?? null) !== 'parent') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $validation = Validator::make($request->all(), [
            'school_id' => ['required', 'integer', 'min:1'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }

        if (!DB::table('child_parent')->where('child_id', $child)->where('parent_id', $actor->id)->exists()) {
            return response()->json(['error' => 'Child unavailable'], 404);
        }

        try {
            return DB::transaction(function () use ($actor, $child, $validation) {
                // Serialize requests from competing guardians of this child.
                $childRecord = DB::table('children')->where('id', $child)->lockForUpdate()->first();
                if (!$childRecord) {
                    return response()->json(['error' => 'Child unavailable'], 404);
                }
                $schoolId = (int) $validation->validated()['school_id'];
                $school = DB::table('schools as s')
                    ->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
                    ->where('s.id', $schoolId)->where('s.is_active', true)
                    ->where(function ($q) {
                        $q->whereNull('s.organization_id')->orWhere('o.is_active', true);
                    })->select('s.id', 's.name')->first();
                if (!$school) {
                    return response()->json(['error' => 'School unavailable'], 404);
                }
                if (DB::table('school_enrollment_requests')
                    ->where('child_id', $child)->where('status', 'pending')->exists()) {
                    return response()->json(['error' => 'Pending request exists'], 409);
                }
                if (DB::table('student_enrollments as e')
                    ->where('e.child_id', $child)->where('e.status', 'active')->exists()) {
                    return response()->json(['error' => 'Active enrollment exists'], 409);
                }
                $id = DB::table('school_enrollment_requests')->insertGetId([
                    'child_id' => $child, 'school_id' => $schoolId,
                    'requested_by' => $actor->id, 'status' => 'pending',
                    'version' => 1, 'created_at' => now(), 'updated_at' => now(),
                ]);
                return response()->json(['request' => [
                    'id' => $id, 'school_id' => $schoolId, 'school_name' => $school->name,
                    'child_id' => $child, 'child_name' => $childRecord->name,
                    'status' => 'pending', 'version' => 1,
                    'created_at' => now()->toIso8601String(), 'reason' => null,
                ]], 201);
            });
        } catch (QueryException $e) {
            if ((string) $e->getCode() === '23505') {
                return response()->json(['error' => 'Pending request exists'], 409);
            }
            report($e);
            return response()->json(['error' => 'Unable to submit request'], 500);
        }
    }
}
