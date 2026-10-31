<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolTransferDestinationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);

        return response()->json(['requests' => DB::table('school_transfer_requests')
            ->where('destination_school_id', $school->id)
            ->where('status', 'pending_destination')
            ->orderBy('id')->limit(100)->get([
                'id', 'child_id', 'source_school_id', 'destination_school_id',
                'status', 'version', 'created_at', 'expires_at',
            ])]);
    }

    public function decide(Request $request, int $transfer): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $request->validate([
            'decision' => ['required', 'in:accept,reject'],
            'version' => ['required', 'integer', 'min:1'],
            'section_id' => ['required_if:decision,accept', 'nullable', 'integer', 'min:1'],
            'idempotency_key' => ['required_if:decision,accept', 'nullable', 'string', 'regex:/^[a-zA-Z0-9_-]{16,128}$/D'],
        ]);

        return DB::transaction(function () use ($request, $school, $transfer, $data) {
            $initial = DB::table('school_transfer_requests')->where('id', $transfer)
                ->where('destination_school_id', $school->id)->first();
            if (!$initial) return response()->json(['error' => 'Transfer unavailable'], 404);

            // All transfer writers serialize on the child before locking the request.
            DB::table('children')->where('id', $initial->child_id)->lockForUpdate()->first();
            $row = DB::table('school_transfer_requests')->where('id', $transfer)
                ->where('destination_school_id', $school->id)->lockForUpdate()->first();
            if (!$row) return response()->json(['error' => 'Transfer unavailable'], 404);

            $actor = $request->attributes->get('jwt_user');
            if ($data['decision'] === 'accept' && $row->status === 'completed'
                && $row->idempotency_key === $data['idempotency_key']
                && (int) $row->destination_section_id === (int) $data['section_id']) {
                return response()->json(['request_id' => $row->id, 'status' => 'completed',
                    'enrollment_id' => $row->destination_enrollment_id]);
            }
            if ($row->status !== 'pending_destination' || (int) $row->version !== (int) $data['version']
                || !$row->guardian_decided_by || ($row->expires_at && now()->greaterThanOrEqualTo($row->expires_at))) {
                return response()->json(['error' => 'Transfer state changed or expired'], 409);
            }
            $destination = DB::table('schools as s')->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
                ->where('s.id', $school->id)->where('s.is_active', true)
                ->where(fn ($q) => $q->whereNull('s.organization_id')->orWhere('o.is_active', true))->exists();
            if (!$destination) return response()->json(['error' => 'Destination unavailable'], 409);

            if ($data['decision'] === 'reject') {
                DB::table('school_transfer_requests')->where('id', $row->id)->update([
                    'status' => 'destination_rejected', 'version' => $row->version + 1,
                    'destination_decided_by' => $actor->id, 'destination_decided_at' => now(), 'updated_at' => now(),
                ]);
                $this->event($row->id, $actor->id, 'destination_reject', 'pending_destination', 'destination_rejected');
                return response()->json(['request_id' => $row->id, 'status' => 'destination_rejected']);
            }

            $section = DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')
                ->where('s.id', $data['section_id'])->where('g.school_id', $school->id)
                ->select('s.id', 's.academic_year_id')->first();
            if (!$section) return response()->json(['error' => 'Section unavailable'], 422);
            DB::table('sections')->where('id', $section->id)->lockForUpdate()->first();
            $source = DB::table('student_enrollments')->where('id', $row->source_enrollment_id)
                ->where('child_id', $row->child_id)->lockForUpdate()->first();
            if (!$source || $source->status !== 'active') return response()->json(['error' => 'Source enrollment changed'], 409);
            $sourceSchool = DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')
                ->where('s.id', $source->section_id)->value('g.school_id');
            if ((int) $sourceSchool !== (int) $row->source_school_id) {
                return response()->json(['error' => 'Source school changed'], 409);
            }
            if (DB::table('student_enrollments')->where('child_id', $row->child_id)
                ->where('status', 'active')->where('id', '!=', $source->id)->exists()) {
                return response()->json(['error' => 'Conflicting active enrollment'], 409);
            }
            if (DB::table('student_enrollments')->where('child_id', $row->child_id)
                ->where('section_id', $section->id)->exists()) {
                return response()->json(['error' => 'Duplicate section enrollment'], 409);
            }
            $target = DB::table('sections')->where('id', $section->id)->first();
            if (isset($target->capacity) && $target->capacity !== null &&
                DB::table('student_enrollments')->where('section_id', $section->id)->where('status', 'active')->count() >= (int) $target->capacity) {
                return response()->json(['error' => 'Destination section full'], 409);
            }

            $now = now();
            DB::table('student_enrollments')->where('id', $source->id)->where('status', 'active')
                ->update(['status' => 'transferred', 'left_on' => $now->toDateString(), 'updated_at' => $now]);
            $enrollmentId = DB::table('student_enrollments')->insertGetId([
                'child_id' => $row->child_id, 'section_id' => $section->id, 'status' => 'active',
                'enrolled_on' => $now->toDateString(), 'left_on' => null,
                'created_at' => $now, 'updated_at' => $now,
            ]);
            DB::table('school_transfer_requests')->where('id', $row->id)->update([
                'status' => 'completed', 'version' => $row->version + 1,
                'destination_section_id' => $section->id, 'destination_enrollment_id' => $enrollmentId,
                'idempotency_key' => $data['idempotency_key'],
                'destination_decided_by' => $actor->id, 'destination_decided_at' => $now,
                'completed_at' => $now, 'updated_at' => $now,
            ]);
            $this->event($row->id, $actor->id, 'destination_accept', 'pending_destination', 'completed');
            return response()->json(['request_id' => $row->id, 'status' => 'completed',
                'enrollment_id' => $enrollmentId], 201);
        }, 3);
    }

    private function event(int $id, int $actor, string $event, string $before, string $after): void
    {
        DB::table('school_transfer_events')->insert([
            'transfer_request_id' => $id, 'actor_id' => $actor, 'event_type' => $event,
            'previous_status' => $before, 'next_status' => $after,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }
}
