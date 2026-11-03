<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class IndependentSchoolSpecialistController extends Controller
{
    private function director(Request $request, bool $lock = false): ?object
    {
        $school = SchoolAdministration::directorSchool($request, $lock);
        return $school && $school->organization_id === null ? $school : null;
    }

    private function specialist(Request $request): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || ($actor->role ?? null) !== 'specialist') return null;
        return DB::table('users')->where('id', $actor->id)
            ->where('role', 'specialist')->whereNotNull('email_verified_at')->first();
    }

    public function employments(Request $request): JsonResponse
    {
        $school = $this->director($request);
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $rows = DB::table('school_specialist_employments as e')
            ->join('users as u', 'u.id', '=', 'e.specialist_id')
            ->where('e.school_id', $school->id)->orderByDesc('e.id')
            ->limit(150)->get(['e.id', 'e.specialist_id', 'u.name as specialist_name',
                'u.email as specialist_email', 'e.offered_at', 'e.accepted_at', 'e.ended_at']);
        return response()->json(['school_id' => (int) $school->id,
            'complete' => true, 'employments' => $rows]);
    }

    public function invite(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'max:190'],
            'expected_school_id' => ['required', 'integer', 'min:1'],
        ]);
        return DB::transaction(function () use ($request, $data) {
            $school = $this->director($request, true);
            if (!$school) return response()->json(['error' => 'Forbidden'], 403);
            $email = mb_strtolower(trim($data['email']));
            $specialist = DB::table('users')->whereRaw('LOWER(email) = ?', [$email])
                ->where('role', 'specialist')->whereNotNull('email_verified_at')->first();
            if (!$specialist) return response()->json(['error' => 'Verified specialist account required'], 422);
            $existing = DB::table('school_specialist_employments')
                ->where('school_id', $school->id)->where('specialist_id', $specialist->id)
                ->whereNull('ended_at')->first();
            if ($existing) return response()->json(['error' => 'Existing active offer or employment'], 409);
            $id = DB::table('school_specialist_employments')->insertGetId([
                'school_id' => $school->id,
                'specialist_id' => $specialist->id,
                'invited_by' => $request->attributes->get('jwt_user')->id,
                'offered_at' => now(), 'accepted_at' => null, 'ended_at' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['school_id' => (int) $school->id,
                'employment_id' => (int) $id, 'status' => 'pending'], 201);
        }, 3);
    }

    public function myOffers(Request $request): JsonResponse
    {
        $specialist = $this->specialist($request);
        if (!$specialist) return response()->json(['error' => 'Forbidden'], 403);
        $rows = DB::table('school_specialist_employments as e')
            ->join('schools as s', 's.id', '=', 'e.school_id')
            ->where('e.specialist_id', $specialist->id)
            ->whereNull('s.organization_id')->where('s.is_active', true)
            ->whereNull('e.ended_at')
            ->orderByDesc('e.id')->limit(100)
            ->get(['e.id', 'e.school_id', 's.name as school_name',
                'e.offered_at', 'e.accepted_at']);
        return response()->json(['complete' => true, 'specialist_id' => (int) $specialist->id,
            'employments' => $rows]);
    }

    public function accept(Request $request, int $employment): JsonResponse
    {
        $specialist = $this->specialist($request);
        if (!$specialist) return response()->json(['error' => 'Forbidden'], 403);
        return DB::transaction(function () use ($specialist, $employment) {
            $offer = DB::table('school_specialist_employments')->where('id', $employment)
                ->where('specialist_id', $specialist->id)->lockForUpdate()->first();
            if (!$offer || $offer->ended_at !== null)
                return response()->json(['error' => 'Offer unavailable'], 404);
            $school = DB::table('schools')->where('id', $offer->school_id)->lockForUpdate()->first();
            if (!$school || !$school->is_active || $school->organization_id !== null)
                return response()->json(['error' => 'School is unavailable'], 403);
            if ($offer->accepted_at !== null) {
                return response()->json(['school_id' => (int) $school->id,
                    'employment_id' => (int) $offer->id, 'status' => 'active']);
            }
            if (now()->greaterThan(\Illuminate\Support\Carbon::parse($offer->offered_at)->addDays(7)))
                return response()->json(['error' => 'Offer expired'], 410);
            DB::table('school_specialist_employments')->where('id', $offer->id)
                ->update(['accepted_at' => now(), 'updated_at' => now()]);
            return response()->json(['school_id' => (int) $school->id,
                'employment_id' => (int) $offer->id, 'status' => 'active']);
        }, 3);
    }

    public function endEmployment(Request $request, int $employment): JsonResponse
    {
        $data = $request->validate(['expected_school_id' => ['required', 'integer', 'min:1']]);
        return DB::transaction(function () use ($request, $employment, $data) {
            $school = $this->director($request, true);
            if (!$school) return response()->json(['error' => 'Forbidden'], 403);
            $row = DB::table('school_specialist_employments')->where('id', $employment)
                ->where('school_id', $school->id)->whereNull('ended_at')->lockForUpdate()->first();
            if (!$row) return response()->json(['error' => 'Employment unavailable'], 404);
            DB::table('school_specialist_employments')->where('id', $row->id)->update([
                'ended_at' => now(), 'updated_at' => now(),
            ]);
            DB::table('school_specialist_assignments')
                ->where('employment_id', $row->id)->whereNull('ended_on')
                ->update(['ended_on' => now()->toDateString(), 'updated_at' => now()]);
            return response()->json(['school_id' => (int) $school->id,
                'employment_id' => (int) $row->id, 'ended' => true]);
        }, 3);
    }

    private function assignmentRow(object $row): array
    {
        return [
            'id' => (int) $row->id,
            'specialist_id' => (int) $row->specialist_id,
            'specialist_name' => $row->specialist_name,
            'starts_on' => (string) $row->starts_on,
            'ended_on' => $row->ended_on === null ? null : (string) $row->ended_on,
            'can_end' => $row->ended_on === null,
        ];
    }

    private function snapshot(object $school): array
    {
        $eligible = DB::table('school_specialist_employments as e')
            ->join('users as u', 'u.id', '=', 'e.specialist_id')
            ->where('e.school_id', $school->id)
            ->whereNotNull('e.accepted_at')->whereNull('e.ended_at')
            ->where('u.role', 'specialist')->whereNotNull('u.email_verified_at')
            ->orderBy('u.id')->get(['e.id as employment_id',
                'e.school_id as employment_school_id', 'u.id', 'u.name']);
        $assignments = DB::table('school_specialist_assignments as a')
            ->join('users as u', 'u.id', '=', 'a.specialist_id')
            ->where('a.school_id', $school->id)->orderByDesc('a.id')
            ->get(['a.id', 'a.specialist_id', 'u.name as specialist_name', 'a.starts_on', 'a.ended_on'])
            ->map(fn ($row) => $this->assignmentRow($row))->all();
        $candidates = $eligible->map(fn ($row) => [
            'id' => (int) $row->id, 'name' => $row->name, 'role' => 'specialist',
            'employment_id' => (int) $row->employment_id,
            'employment_school_id' => (int) $row->employment_school_id,
            'employment_active' => true,
        ])->all();
        // The revision represents current employment AND assignments, so a
        // stale choice cannot survive either employment revocation or reassignment.
        $revision = hash('sha256', json_encode([$candidates, $assignments], JSON_UNESCAPED_UNICODE));
        return [
            'contract_version' => 1, 'complete' => true,
            'organization_id' => null,
            'school_id' => (int) $school->id, 'school_name' => $school->name,
            'revision' => $revision,
            'effective_on' => now()->toDateString(),
            'capabilities' => ['can_assign' => true],
            'eligible_specialists' => $candidates,
            'assignments' => $assignments,
        ];
    }

    public function assignments(Request $request): JsonResponse
    {
        $school = $this->director($request);
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        return response()->json($this->snapshot($school));
    }

    public function assign(Request $request): JsonResponse
    {
        $input = $request->validate([
            'expected_school_id' => ['required', 'integer', 'min:1'],
            'specialist_id' => ['required', 'integer', 'min:1'],
            'expected_revision' => ['required', 'string', 'size:64'],
            'effective_on' => ['required', 'date_format:Y-m-d'],
            'idempotency_key' => ['required', 'regex:/^[0-9a-f]{32}$/D'],
        ]);
        return DB::transaction(function () use ($request, $input) {
            $school = $this->director($request, true);
            if (!$school) return response()->json(['error' => 'Forbidden'], 403);
            if ($input['effective_on'] !== now()->toDateString())
                return response()->json(['error' => 'Effective date changed'], 409);
            $existingKey = DB::table('school_specialist_assignments')
                ->where('idempotency_key', $input['idempotency_key'])->first();
            if ($existingKey) {
                if ((int) $existingKey->school_id !== (int) $school->id
                    || (int) $existingKey->specialist_id !== (int) $input['specialist_id'])
                    return response()->json(['error' => 'Idempotency conflict'], 409);
                $row = DB::table('school_specialist_assignments as a')->join('users as u', 'u.id', '=', 'a.specialist_id')
                    ->where('a.id', $existingKey->id)->first(['a.id', 'a.specialist_id',
                        'u.name as specialist_name', 'a.starts_on', 'a.ended_on']);
                return response()->json(['organization_id' => null, 'school_id' => (int) $school->id,
                    'assignment' => $this->assignmentRow($row)], 201);
            }
            $before = $this->snapshot($school);
            if (!hash_equals($before['revision'], $input['expected_revision']))
                return response()->json(['error' => 'Assignments changed'], 409);
            $eligible = collect($before['eligible_specialists'])->firstWhere('id', (int) $input['specialist_id']);
            if (!$eligible) return response()->json(['error' => 'Specialist is not active school staff'], 422);
            if (DB::table('school_specialist_assignments')->where('school_id', $school->id)
                ->where('specialist_id', $input['specialist_id'])->whereNull('ended_on')->exists()) {
                return response()->json(['error' => 'Specialist already assigned'], 409);
            }
            $id = DB::table('school_specialist_assignments')->insertGetId([
                'school_id' => $school->id, 'employment_id' => $eligible['employment_id'],
                'specialist_id' => $input['specialist_id'],
                'assigned_by' => $request->attributes->get('jwt_user')->id,
                'starts_on' => $input['effective_on'], 'ended_on' => null,
                'idempotency_key' => $input['idempotency_key'],
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $row = DB::table('school_specialist_assignments as a')->join('users as u', 'u.id', '=', 'a.specialist_id')
                ->where('a.id', $id)->first(['a.id', 'a.specialist_id', 'u.name as specialist_name',
                    'a.starts_on', 'a.ended_on']);
            return response()->json(['organization_id' => null, 'school_id' => (int) $school->id,
                'assignment' => $this->assignmentRow($row)], 201);
        }, 3);
    }

    public function endAssignment(Request $request, int $assignment): JsonResponse
    {
        $input = $request->validate([
            'expected_school_id' => ['required', 'integer', 'min:1'],
            'expected_specialist_id' => ['required', 'integer', 'min:1'],
            'expected_revision' => ['required', 'string', 'size:64'],
            'effective_on' => ['required', 'date_format:Y-m-d'],
            'idempotency_key' => ['required', 'regex:/^[0-9a-f]{32}$/D'],
        ]);
        return DB::transaction(function () use ($request, $assignment, $input) {
            $school = $this->director($request, true);
            if (!$school) return response()->json(['error' => 'Forbidden'], 403);
            $row = DB::table('school_specialist_assignments')->where('id', $assignment)
                ->where('school_id', $school->id)->lockForUpdate()->first();
            if (!$row || (int) $row->specialist_id !== (int) $input['expected_specialist_id'])
                return response()->json(['error' => 'Assignment unavailable'], 404);
            if ($row->ended_on !== null) {
                if ($row->end_idempotency_key !== $input['idempotency_key'])
                    return response()->json(['error' => 'Assignment already ended'], 409);
            } else {
                $before = $this->snapshot($school);
                if (!hash_equals($before['revision'], $input['expected_revision'])
                    || $input['effective_on'] !== now()->toDateString())
                    return response()->json(['error' => 'Assignment changed'], 409);
                DB::table('school_specialist_assignments')->where('id', $row->id)->update([
                    'ended_on' => $input['effective_on'],
                    'end_idempotency_key' => $input['idempotency_key'],
                    'updated_at' => now(),
                ]);
            }
            $receipt = DB::table('school_specialist_assignments as a')
                ->join('users as u', 'u.id', '=', 'a.specialist_id')
                ->where('a.id', $row->id)->first(['a.id', 'a.specialist_id',
                    'u.name as specialist_name', 'a.starts_on', 'a.ended_on']);
            return response()->json(['organization_id' => null, 'school_id' => (int) $school->id,
                'assignment' => $this->assignmentRow($receipt)]);
        }, 3);
    }

    public function mySchools(Request $request): JsonResponse
    {
        $specialist = $this->specialist($request);
        if (!$specialist) return response()->json(['error' => 'Forbidden'], 403);
        $rows = DB::table('school_specialist_assignments as a')
            ->join('school_specialist_employments as e', 'e.id', '=', 'a.employment_id')
            ->join('schools as s', 's.id', '=', 'a.school_id')
            ->where('a.specialist_id', $specialist->id)->whereNull('a.ended_on')
            ->where('e.specialist_id', $specialist->id)
            ->whereNotNull('e.accepted_at')->whereNull('e.ended_at')
            ->where('e.school_id', DB::raw('a.school_id'))
            ->where('s.is_active', true)->whereNull('s.organization_id')
            ->orderBy('s.id')->get(['s.id as school_id', 's.name as school_name', 'a.id as assignment_id']);
        return response()->json(['contract_version' => 1, 'complete' => true,
            'specialist_id' => (int) $specialist->id,
            'schools' => $rows->map(fn ($row) => [
                'school_id' => (int) $row->school_id,
                'organization_id' => null,
                'assignment_id' => (int) $row->assignment_id,
                'school_name' => $row->school_name,
            ])->values()]);
    }
}
