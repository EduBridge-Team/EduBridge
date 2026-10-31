<?php

namespace App\Http\Controllers;

use App\Support\SchoolPromotionRoster;
use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SchoolAnnualPromotionController extends Controller
{
    private function input(Request $request, bool $decisions = false): array
    {
        return $request->validate(['source_year_id' => ['required', 'integer', 'min:1'], 'target_year_id' => ['required', 'integer', 'min:1'],
            ...($decisions ? ['roster_revision' => ['required', 'string', 'size:64'], 'decisions' => ['required', 'array', 'min:1', 'max:5000'],
                'decisions.*.enrollment_id' => ['required', 'integer', 'distinct'], 'decisions.*.decision' => ['required', 'in:promoted,repeating,transferred'],
                'decisions.*.target_section_id' => ['sometimes', 'integer', 'min:1'], 'decisions.*.target_school_id' => ['sometimes', 'integer', 'min:1']] : [])]);
    }

    private function digest(array $data): string
    {
        $decisions = $data['decisions'];
        usort($decisions, fn ($a, $b) => $a['enrollment_id'] <=> $b['enrollment_id']);
        $decisions = array_map(fn ($row) => ['enrollment_id' => (int) $row['enrollment_id'], 'decision' => $row['decision'],
            'target_section_id' => isset($row['target_section_id']) ? (int) $row['target_section_id'] : null,
            'target_school_id' => isset($row['target_school_id']) ? (int) $row['target_school_id'] : null], $decisions);
        return hash('sha256', json_encode([(int) $data['source_year_id'], (int) $data['target_year_id'], $data['roster_revision'], $decisions]));
    }

    public function roster(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $this->input($request);
        return response()->json(app(SchoolPromotionRoster::class)->load($school->id, $data['source_year_id'], $data['target_year_id']));
    }

    public function destinations(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        return response()->json(['schools' => DB::table('schools as s')->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('s.id', '!=', $school->id)->where('s.is_active', true)
            ->where(fn ($q) => $q->whereNull('s.organization_id')->orWhere('o.is_active', true))->orderBy('s.name')->get(['s.id', 's.name']),
            'notice' => 'Transfer records the source-school decision only; destination enrollment and guardian consent remain separate.']);
    }

    public function preview(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $this->input($request, true);
        $service = app(SchoolPromotionRoster::class);
        $roster = $service->load($school->id, $data['source_year_id'], $data['target_year_id']);
        $errors = $service->validateDecisions($roster, $data['decisions']);
        if (!hash_equals($roster['revision'], $data['roster_revision'])) $errors[] = 'Roster changed; reload before approval';
        $token = $errors ? '' : Str::random(64);
        if ($token !== '') DB::table('school_promotion_previews')->insert([
            'school_id' => $school->id, 'actor_id' => $request->attributes->get('jwt_user')->id,
            'token_hash' => hash('sha256', $token), 'payload_hash' => $this->digest($data),
            'expires_at' => now()->addMinutes(15), 'created_at' => now(), 'updated_at' => now(),
        ]);
        return response()->json(['school_id' => (int) $school->id, 'source_year_id' => (int) $data['source_year_id'],
            'target_year_id' => (int) $data['target_year_id'], 'roster_revision' => $roster['revision'],
            'ready' => !$errors, 'blocking_errors' => $errors, 'preview_token' => $token]);
    }

    public function approve(Request $request): JsonResponse
    {
        $data = $this->input($request, true);
        $extra = $request->validate(['preview_token' => ['required', 'string', 'size:64'],
            'idempotency_key' => ['required', 'string', 'regex:/^[a-zA-Z0-9_-]{16,128}$/D']]);
        return DB::transaction(function () use ($request, $data, $extra) {
            $school = SchoolScopedAccess::resolve($request, 'enrollment');
            if (!$school) return response()->json(['error' => 'Forbidden'], 403);
            DB::table('schools')->where('id', $school->id)->lockForUpdate()->first();
            $checked = SchoolScopedAccess::resolve($request, 'enrollment');
            if (!$checked || (int) $checked->id !== (int) $school->id) return response()->json(['error' => 'Forbidden'], 403);
            $actor = $request->attributes->get('jwt_user')->id;
            $hash = $this->digest($data);
            $previous = DB::table('school_promotion_operations')->where('operation_id', $extra['idempotency_key'])->first();
            if ($previous) {
                if ((int) $previous->school_id !== (int) $school->id || (int) $previous->actor_id !== (int) $actor
                    || !hash_equals($previous->payload_hash, $hash)) return response()->json(['error' => 'Idempotency conflict'], 409);
                return response()->json(json_decode($previous->receipt, true));
            }
            $preview = DB::table('school_promotion_previews')->where('token_hash', hash('sha256', $extra['preview_token']))
                ->where('school_id', $school->id)->where('actor_id', $actor)->lockForUpdate()->first();
            if (!$preview || $preview->used_at || now()->greaterThanOrEqualTo($preview->expires_at)
                || !hash_equals($preview->payload_hash, $hash)) return response()->json(['error' => 'Preview expired or changed'], 409);
            $sectionIds = DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')
                ->where('g.school_id', $school->id)->whereIn('s.academic_year_id', [$data['source_year_id'], $data['target_year_id']])->pluck('s.id');
            DB::table('sections')->whereIn('id', $sectionIds)->orderBy('id')->lockForUpdate()->get();
            $children = DB::table('student_enrollments')->whereIn('id', array_column($data['decisions'], 'enrollment_id'))->pluck('child_id');
            DB::table('children')->whereIn('id', $children)->orderBy('id')->lockForUpdate()->get();
            $service = app(SchoolPromotionRoster::class);
            $roster = $service->load($school->id, $data['source_year_id'], $data['target_year_id']);
            if (!hash_equals($roster['revision'], $data['roster_revision']) || $service->validateDecisions($roster, $data['decisions'])) {
                return response()->json(['error' => 'Roster changed; preview again'], 409);
            }
            $students = array_column($roster['students'], null, 'enrollment_id');
            $counts = ['promoted' => 0, 'repeating' => 0, 'transferred' => 0];
            foreach ($data['decisions'] as $decision) {
                $student = $students[$decision['enrollment_id']];
                $closed = DB::table('student_enrollments')->where('id', $decision['enrollment_id'])->where('status', 'active')
                    ->update(['status' => 'transferred', 'left_on' => $roster['target_starts_on'], 'updated_at' => now()]);
                if ($closed !== 1) throw new \RuntimeException('Enrollment changed during approval');
                if ($decision['decision'] !== 'transferred') DB::table('student_enrollments')->insert([
                    'section_id' => $decision['target_section_id'], 'child_id' => $student['child_id'], 'status' => 'active',
                    'enrolled_on' => $roster['target_starts_on'], 'left_on' => null, 'created_at' => now(), 'updated_at' => now(),
                ]);
                $counts[$decision['decision']]++;
            }
            $receipt = ['operation_id' => $extra['idempotency_key'], 'school_id' => (int) $school->id,
                'source_year_id' => (int) $data['source_year_id'], 'target_year_id' => (int) $data['target_year_id'],
                'status' => 'completed', 'counts' => $counts, 'transfer_scope' => 'source_school_only'];
            DB::table('school_promotion_operations')->insert(['operation_id' => $extra['idempotency_key'], 'school_id' => $school->id,
                'actor_id' => $actor, 'source_year_id' => $data['source_year_id'], 'target_year_id' => $data['target_year_id'],
                'payload_hash' => $hash, 'receipt' => json_encode($receipt), 'decisions' => json_encode($data['decisions']), 'created_at' => now(), 'updated_at' => now()]);
            DB::table('school_promotion_previews')->where('id', $preview->id)->update(['used_at' => now(), 'updated_at' => now()]);
            return response()->json($receipt);
        }, 3);
    }

    public function operation(Request $request, string $operation): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $row = DB::table('school_promotion_operations')->where('school_id', $school->id)->where('operation_id', $operation)->first();
        return $row ? response()->json(json_decode($row->receipt, true)) : response()->json(['error' => 'Operation not found'], 404);
    }

    public function history(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $request->validate(['year_id' => ['required', 'integer', 'min:1']]);
        $rows = DB::table('school_promotion_operations')->where('school_id', $school->id)->where('source_year_id', $data['year_id'])
            ->orderByDesc('created_at')->limit(5001)->get();
        return response()->json(['school_id' => (int) $school->id, 'complete' => $rows->count() <= 5000,
            'operations' => $rows->map(fn ($row) => json_decode($row->receipt, true))]);
    }
}
