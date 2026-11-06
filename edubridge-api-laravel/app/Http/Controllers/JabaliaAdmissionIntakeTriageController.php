<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class JabaliaAdmissionIntakeTriageController extends Controller
{
    // These are administrative queue labels only. None represents verification,
    // a clinical opinion, counselor authorization, rejection or approval.
    private const STATES = [
        'evidence_followup_needed',
        'awaiting_counselor_assignment',
        'administrative_followup_needed',
    ];

    private function pendingRequest(Request $request, int $enrollmentRequest): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || ($actor->role ?? null) === 'school') return null;

        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school || !in_array($school->management_role ?? null, ['director', 'deputy_director'], true)) {
            return null;
        }

        return DB::table('school_enrollment_requests as r')
            ->join('schools as s', 's.id', '=', 'r.school_id')
            ->join('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('r.id', $enrollmentRequest)
            ->where('r.school_id', $school->id)
            ->where('r.status', 'pending')
            ->where('s.is_active', true)
            ->where('o.is_active', true)
            ->where('o.slug', 'jabalia')
            ->select('r.id', 'r.child_id', 'r.school_id', 'r.version',
                'o.id as organization_id')
            ->first();
    }

    private function ready(): bool
    {
        return Schema::hasTable('jabalia_admission_intake_events');
    }

    private function history(object $target): JsonResponse
    {
        $events = DB::table('jabalia_admission_intake_events')
            ->where('organization_id', $target->organization_id)
            ->where('school_id', $target->school_id)
            ->where('child_id', $target->child_id)
            ->where('enrollment_request_id', $target->id)
            ->orderByDesc('id')
            ->select(['id', 'state', 'request_version', 'actor_id',
                'management_role', 'created_at'])
            ->paginate(20);
        $latest = $events->items()[0] ?? null;

        return response()->json([
            'school_id' => (int) $target->school_id,
            'request_id' => (int) $target->id,
            'request_version' => (int) $target->version,
            'latest_event_id' => (int) ($latest->id ?? 0),
            'current_state' => $latest->state ?? 'untracked',
            'events' => $events,
            'preparation_only' => true,
            'counselor_review_completed' => false,
            'administration_approved' => false,
            'approval_allowed' => false,
            'note' => 'إجراء تنظيمي فقط، ولا يثبت مراجعة المرشد أو صحة المستندات أو الموافقة على قبول الطالب',
        ]);
    }

    public function show(Request $request, int $enrollmentRequest): JsonResponse
    {
        $target = $this->pendingRequest($request, $enrollmentRequest);
        if (!$target) return response()->json(['error' => 'Not found'], 404);
        if (!$this->ready()) {
            return response()->json(['error' => 'Intake audit not yet available'], 503);
        }
        return $this->history($target);
    }

    public function store(Request $request, int $enrollmentRequest): JsonResponse
    {
        $target = $this->pendingRequest($request, $enrollmentRequest);
        if (!$target) return response()->json(['error' => 'Not found'], 404);
        if (!$this->ready()) {
            return response()->json(['error' => 'Intake audit not yet available'], 503);
        }

        $data = $request->validate([
            'state' => ['required', Rule::in(self::STATES)],
            'expected_request_version' => ['required', 'integer', 'min:1'],
            'expected_event_id' => ['required', 'integer', 'min:0'],
        ]);

        return DB::transaction(function () use ($request, $enrollmentRequest, $target, $data) {
            // Prevent concurrent changes and stale saves after a parent's
            // application update/cancellation or another administrator's triage.
            DB::table('schools')->where('id', $target->school_id)->lockForUpdate()->first();
            $current = DB::table('school_enrollment_requests')
                ->where('id', $enrollmentRequest)->where('school_id', $target->school_id)
                ->lockForUpdate()->first();
            $authorized = $this->pendingRequest($request, $enrollmentRequest);
            if (!$authorized || !$current || $current->status !== 'pending') {
                return response()->json(['error' => 'Not found'], 404);
            }
            if ((int) $current->version !== (int) $data['expected_request_version']) {
                return response()->json(['error' => 'Application updated; refresh required'], 409);
            }

            $last = DB::table('jabalia_admission_intake_events')
                ->where('organization_id', $target->organization_id)
                ->where('school_id', $target->school_id)
                ->where('child_id', $target->child_id)
                ->where('enrollment_request_id', $enrollmentRequest)
                ->orderByDesc('id')->first();

            if ((int) ($last->id ?? 0) !== (int) $data['expected_event_id']) {
                return response()->json(['error' => 'Triage updated; refresh required'], 409);
            }
            if (($last->state ?? null) === $data['state']) {
                return response()->json(['error' => 'Triage state already recorded'], 409);
            }

            $actor = $request->attributes->get('jwt_user');
            $schoolAccess = SchoolScopedAccess::resolve($request, 'enrollment');
            DB::table('jabalia_admission_intake_events')->insert([
                'organization_id' => $target->organization_id,
                'school_id' => $target->school_id,
                'enrollment_request_id' => $enrollmentRequest,
                'child_id' => $target->child_id,
                'request_version' => $current->version,
                'state' => $data['state'],
                'actor_id' => $actor->id,
                'management_role' => $schoolAccess->management_role,
                'created_at' => now(),
            ]);

            // Intentionally never mutate the parent application status, section
            // enrollment, medical evidence, or counselor/admin signoff fields.
            return $this->history($authorized);
        });
    }
}
