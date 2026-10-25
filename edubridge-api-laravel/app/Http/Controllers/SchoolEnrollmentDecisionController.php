<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SchoolEnrollmentDecisionController extends Controller
{
    public function decide(Request $request, int $enrollmentRequest): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || $actor->role !== 'school') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $validation = Validator::make($request->all(), [
            'expected_version' => ['required', 'integer', 'min:1'],
            'decision' => ['required', 'in:approved,rejected'],
            'section_id' => ['required_if:decision,approved', 'nullable', 'integer', 'min:1'],
            'reason' => ['required_if:decision,rejected', 'nullable', 'string', 'max:1000'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $data = $validation->validated();
        if ($data['decision'] === 'rejected' && trim((string) ($data['reason'] ?? '')) === '') {
            return response()->json(['errors' => ['reason' => ['Reason required']]], 422);
        }

        $schools = DB::table('school_accounts as a')
            ->join('schools as s', 's.id', '=', 'a.school_id')
            ->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('a.user_id', $actor->id)->where('s.is_active', true)
            ->where(function ($q) {
                $q->whereNull('s.organization_id')->orWhere('o.is_active', true);
            })->select('s.id', 's.name')->limit(2)->get();
        if ($schools->count() !== 1) {
            return response()->json(['error' => 'School unavailable'], 403);
        }
        $school = $schools->first();
        $candidate = DB::table('school_enrollment_requests')
            ->where('id', $enrollmentRequest)->where('school_id', $school->id)->first();
        if (!$candidate) {
            return response()->json(['error' => 'Request unavailable'], 404);
        }

        return DB::transaction(function () use ($actor, $data, $candidate, $school, $enrollmentRequest) {
            // All decisions and guardian cancellations serialize on the child row.
            $child = DB::table('children')->where('id', $candidate->child_id)
                ->lockForUpdate()->first();
            if (!$child) {
                return response()->json(['error' => 'Child unavailable'], 404);
            }
            $record = DB::table('school_enrollment_requests')
                ->where('id', $enrollmentRequest)->where('school_id', $school->id)
                ->lockForUpdate()->first();
            if (!$record || $record->status !== 'pending'
                || (int) $record->version !== (int) $data['expected_version']) {
                return response()->json(['error' => 'Request state changed'], 409);
            }

            $enrollment = null;
            if ($data['decision'] === 'approved') {
                $section = DB::table('sections as s')
                    ->join('grades as g', 'g.id', '=', 's.grade_id')
                    ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
                    ->where('s.id', $data['section_id'])
                    ->where('g.school_id', $school->id)
                    ->where('y.school_id', $school->id)
                    ->where('g.is_active', true)->where('y.is_current', true)
                    ->select('s.id', 's.capacity')->lockForUpdate()->first();
                if (!$section) {
                    return response()->json(['error' => 'Section unavailable'], 422);
                }
                if (DB::table('student_enrollments')->where('child_id', $child->id)
                    ->where('status', 'active')->exists()) {
                    return response()->json(['error' => 'Active enrollment exists'], 409);
                }
                if ($section->capacity !== null &&
                    DB::table('student_enrollments')->where('section_id', $section->id)
                        ->where('status', 'active')->count() >= (int) $section->capacity) {
                    return response()->json(['error' => 'Section is full'], 409);
                }
                $id = DB::table('student_enrollments')->insertGetId([
                    'child_id' => $child->id, 'section_id' => $section->id,
                    'status' => 'active', 'enrolled_on' => now()->toDateString(),
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                $enrollment = ['id' => $id, 'school_id' => (int) $school->id,
                    'school_name' => $school->name, 'child_id' => (int) $child->id,
                    'section_id' => (int) $section->id, 'status' => 'active'];
            }

            DB::table('school_enrollment_requests')->where('id', $record->id)->update([
                'status' => $data['decision'], 'version' => $record->version + 1,
                'reason' => $data['reason'] ?? null, 'decided_by' => $actor->id,
                'decided_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['request' => [
                'id' => (int) $record->id, 'school_id' => (int) $school->id,
                'school_name' => $school->name, 'child_id' => (int) $child->id,
                'child_name' => $child->name, 'status' => $data['decision'],
                'version' => (int) $record->version + 1, 'created_at' => $record->created_at,
                'reason' => $data['reason'] ?? null,
            ], 'enrollment' => $enrollment]);
        });
    }
}
