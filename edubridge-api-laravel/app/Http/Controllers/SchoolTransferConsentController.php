<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolTransferConsentController extends Controller
{
    public function create(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $request->validate([
            'source_enrollment_id' => ['required', 'integer', 'min:1'],
            'destination_school_id' => ['required', 'integer', 'min:1'],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);
        return DB::transaction(function () use ($request, $school, $data) {
            $source = DB::table('student_enrollments as e')
                ->join('sections as s', 's.id', '=', 'e.section_id')
                ->join('grades as g', 'g.id', '=', 's.grade_id')
                ->where('e.id', $data['source_enrollment_id'])
                ->where('g.school_id', $school->id)
                ->select('e.id', 'e.child_id', 'e.status')->first();
            if (!$source) return response()->json(['error' => 'Enrollment unavailable'], 404);
            DB::table('children')->where('id', $source->child_id)->lockForUpdate()->first();
            if ($source->status !== 'active' || !DB::table('student_enrollments')->where('id', $source->id)->where('status', 'active')->exists()) {
                return response()->json(['error' => 'Enrollment is no longer active'], 409);
            }
            $destination = DB::table('schools as s')->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
                ->where('s.id', $data['destination_school_id'])->where('s.id', '!=', $school->id)
                ->where('s.is_active', true)
                ->where(fn ($q) => $q->whereNull('s.organization_id')->orWhere('o.is_active', true))->exists();
            if (!$destination) return response()->json(['error' => 'Destination unavailable'], 404);
            if (DB::table('school_transfer_requests')->where('child_id', $source->child_id)
                ->whereIn('status', ['pending_guardian', 'pending_destination'])->exists()) {
                return response()->json(['error' => 'Pending transfer exists'], 409);
            }
            $actor = $request->attributes->get('jwt_user');
            $id = DB::table('school_transfer_requests')->insertGetId([
                'child_id' => $source->child_id, 'source_enrollment_id' => $source->id,
                'source_school_id' => $school->id, 'destination_school_id' => $data['destination_school_id'],
                'requested_by' => $actor->id, 'reason' => $data['reason'] ?? null,
                'status' => 'pending_guardian', 'version' => 1, 'expires_at' => now()->addDays(30),
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $this->event($id, $actor->id, 'created', null, 'pending_guardian');
            return response()->json(['request_id' => $id, 'status' => 'pending_guardian'], 201);
        }, 3);
    }

    public function guardianIndex(Request $request, int $child): JsonResponse
    {
        if (!$this->guardian($request, $child)) return response()->json(['error' => 'Child unavailable'], 404);
        return response()->json(['requests' => DB::table('school_transfer_requests')
            ->where('child_id', $child)->orderByDesc('id')
            ->get(['id', 'child_id', 'source_school_id', 'destination_school_id', 'status', 'version', 'reason', 'created_at'])]);
    }

    public function guardianDecision(Request $request, int $child, int $transfer): JsonResponse
    {
        if (!$this->guardian($request, $child)) return response()->json(['error' => 'Child unavailable'], 404);
        $data = $request->validate(['decision' => ['required', 'in:approve,reject'], 'version' => ['required', 'integer', 'min:1']]);
        return DB::transaction(function () use ($request, $child, $transfer, $data) {
            DB::table('children')->where('id', $child)->lockForUpdate()->first();
            $row = DB::table('school_transfer_requests')->where('id', $transfer)->where('child_id', $child)->lockForUpdate()->first();
            if (!$row) return response()->json(['error' => 'Transfer unavailable'], 404);
            if ($row->status !== 'pending_guardian' || (int) $row->version !== (int) $data['version'] || ($row->expires_at && now()->greaterThanOrEqualTo($row->expires_at))) {
                return response()->json(['error' => 'Transfer state changed or expired'], 409);
            }
            if (!DB::table('student_enrollments')->where('id', $row->source_enrollment_id)->where('child_id', $child)->where('status', 'active')->exists()) {
                return response()->json(['error' => 'Source enrollment changed'], 409);
            }
            $next = $data['decision'] === 'approve' ? 'pending_destination' : 'guardian_rejected';
            $actor = $request->attributes->get('jwt_user');
            DB::table('school_transfer_requests')->where('id', $transfer)->update([
                'status' => $next, 'version' => $row->version + 1,
                'guardian_decided_by' => $actor->id, 'guardian_decided_at' => now(), 'updated_at' => now(),
            ]);
            $this->event($transfer, $actor->id, 'guardian_' . $data['decision'], $row->status, $next);
            return response()->json(['request_id' => $transfer, 'status' => $next, 'version' => $row->version + 1]);
        }, 3);
    }

    private function guardian(Request $request, int $child): bool
    {
        $actor = $request->attributes->get('jwt_user');
        return $actor && ($actor->role ?? null) === 'parent'
            && DB::table('child_parent')->where('child_id', $child)->where('parent_id', $actor->id)->exists();
    }

    private function event(int $id, int $actor, string $event, ?string $before, string $after): void
    {
        DB::table('school_transfer_events')->insert([
            'transfer_request_id' => $id, 'actor_id' => $actor, 'event_type' => $event,
            'previous_status' => $before, 'next_status' => $after,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }
}
