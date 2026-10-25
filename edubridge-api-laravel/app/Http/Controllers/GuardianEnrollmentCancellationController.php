<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class GuardianEnrollmentCancellationController extends Controller
{
    public function cancel(Request $request, int $child, int $enrollmentRequest): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || $actor->role !== 'parent') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $validation = Validator::make($request->all(), [
            'expected_version' => ['required', 'integer', 'min:1'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        if (!DB::table('child_parent')->where('child_id', $child)
            ->where('parent_id', $actor->id)->exists()) {
            return response()->json(['error' => 'Child unavailable'], 404);
        }

        return DB::transaction(function () use ($actor, $child, $enrollmentRequest, $validation) {
            $childRecord = DB::table('children')->where('id', $child)->lockForUpdate()->first();
            if (!$childRecord) {
                return response()->json(['error' => 'Child unavailable'], 404);
            }
            $record = DB::table('school_enrollment_requests as r')
                ->join('schools as s', 's.id', '=', 'r.school_id')
                ->where('r.id', $enrollmentRequest)->where('r.child_id', $child)
                ->where('r.requested_by', $actor->id)
                ->select('r.*', 's.name as school_name')->first();
            if (!$record) {
                return response()->json(['error' => 'Request unavailable'], 404);
            }
            if ($record->status !== 'pending'
                || (int) $record->version !== (int) $validation->validated()['expected_version']) {
                return response()->json(['error' => 'Request state changed'], 409);
            }
            $updated = DB::table('school_enrollment_requests')
                ->where('id', $record->id)->where('status', 'pending')
                ->where('version', $record->version)
                ->update(['status' => 'cancelled', 'version' => $record->version + 1,
                    'updated_at' => now()]);
            if (!$updated) {
                return response()->json(['error' => 'Request state changed'], 409);
            }
            return response()->json(['request' => [
                'id' => (int) $record->id,
                'school_id' => (int) $record->school_id,
                'school_name' => $record->school_name,
                'child_id' => $child,
                'child_name' => $childRecord->name,
                'status' => 'cancelled',
                'version' => (int) $record->version + 1,
                'created_at' => $record->created_at,
                'reason' => $record->reason,
            ]]);
        });
    }
}
