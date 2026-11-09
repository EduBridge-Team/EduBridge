<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class InstitutionDirectorDirectoryController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->authorized($request)) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->schoolWithinOrganization($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'School not found'], 404);
        }
        $profiles = DB::table('institution_director_profiles')
            ->where('school_id', $school)->orderBy('id')->get()->map(fn ($p) => $this->profile($p));
        $history = DB::table('institution_director_assignments')
            ->where('school_id', $school)->orderBy('id')->get()->map(fn ($a) => $this->assignment($a));
        return response()->json([
            'school_id' => $school,
            'directors' => $profiles,
            'assignments' => $history,
        ]);
    }

    public function store(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->authorized($request)) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->schoolWithinOrganization($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'School not found'], 404);
        }
        $data = $this->validatedProfile($request);
        return DB::transaction(function () use ($request, $school, $data) {
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            if ($this->duplicateEmail($school, $data['email'])) {
                return response()->json(['errors' => ['email' => ['Email already registered for this school']]], 422);
            }
            $actorId = $request->attributes->get('jwt_user')->id;
            $id = DB::table('institution_director_profiles')->insertGetId(array_merge($data, [
                'school_id' => $school, 'identity_user_id' => null,
                'created_by' => $actorId, 'updated_by' => $actorId,
                'created_at' => now(), 'updated_at' => now(),
            ]));
            return response()->json([
                'director' => $this->profile(DB::table('institution_director_profiles')->find($id)),
            ], 201);
        }, 3);
    }

    public function update(Request $request, string $organizationSlug, int $school, int $director): JsonResponse
    {
        if (!$this->authorized($request)) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->schoolWithinOrganization($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'School not found'], 404);
        }
        $data = $this->validatedProfile($request);
        return DB::transaction(function () use ($request, $school, $director, $data) {
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            $profile = DB::table('institution_director_profiles')
                ->where('school_id', $school)->where('id', $director)->lockForUpdate()->first();
            if (!$profile) return response()->json(['error' => 'Director not found'], 404);
            // Editing a contact must not silently switch an operating identity.
            if ($profile->identity_user_id !== null && $profile->email !== $data['email']) {
                return response()->json(['error' => 'Verified identity email cannot be edited'], 409);
            }
            if ($this->duplicateEmail($school, $data['email'], $director)) {
                return response()->json(['errors' => ['email' => ['Email already registered for this school']]], 422);
            }
            DB::table('institution_director_profiles')->where('id', $director)->update(
                array_merge($data, [
                    'updated_by' => $request->attributes->get('jwt_user')->id, 'updated_at' => now(),
                ])
            );
            return response()->json([
                'director' => $this->profile(DB::table('institution_director_profiles')->find($director)),
            ]);
        }, 3);
    }

    /**
     * Appoint an already verified, dedicated director identity. A directory
     * profile alone never grants login rights or authorizes a school operation.
     */
    public function assign(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->authorized($request)) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->schoolWithinOrganization($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'School not found'], 404);
        }
        $data = Validator::make($request->all(), [
            'director_id' => ['required', 'integer', 'min:1'],
            'starts_on' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            // Explicit optimistic-concurrency assertion is mandatory, even if null.
            'replace_assignment_id' => ['present', 'nullable', 'integer', 'min:1'],
        ])->validate();

        return DB::transaction(function () use ($request, $organizationSlug, $school, $data) {
            // A common school-row lock serializes assignment mutations with
            // dedicated invitation activation and revocation.
            $schoolRow = DB::table('schools')->where('id', $school)
                ->where('organization_id', $request->attributes->get('organization')->id)
                ->where('is_active', true)->lockForUpdate()->first();
            if (!$schoolRow || !$this->schoolWithinOrganization($request, $organizationSlug, $school)) {
                return response()->json(['error' => 'School not found'], 404);
            }
            if (!$this->authorized($request)) return response()->json(['error' => 'Forbidden'], 403);

            $current = DB::table('institution_director_assignments')->where('school_id', $school)
                ->whereNull('ended_on')->lockForUpdate()->first();
            $currentId = $current ? (int) $current->id : null;
            $expectedId = $data['replace_assignment_id'] === null
                ? null : (int) $data['replace_assignment_id'];
            if ($currentId !== $expectedId) {
                return response()->json(['error' => 'Director assignment changed; refresh first'], 409);
            }

            $profile = DB::table('institution_director_profiles')
                ->where('school_id', $school)->where('id', $data['director_id'])
                ->lockForUpdate()->first();
            if (!$profile) return response()->json(['error' => 'Director not found'], 404);
            if ($current && (int) $current->director_id === (int) $profile->id) {
                return response()->json(['error' => 'Director already holds this assignment'], 409);
            }
            if ($current && $data['starts_on'] < $current->starts_on) {
                return response()->json(['error' => 'Replacement date precedes current appointment'], 422);
            }

            [$consistent, $oldOperational] = $this->currentOperationalAppointment($school, $current);
            if (!$consistent) {
                return response()->json(['error' => 'Director appointment state needs reconciliation'], 409);
            }

            // The only supported way to create a dedicated director identity
            // is a verified invitation. Existing unrelated user roles cannot
            // be promoted through profile or assignment APIs.
            if ($profile->identity_user_id === null) {
                return response()->json(['error' => 'Director invitation activation is required'], 409);
            }
            $account = DB::table('users')->where('id', $profile->identity_user_id)
                ->lockForUpdate()->first();
            if (!$account || $account->role !== 'school_director'
                || mb_strtolower(trim((string) $account->email)) !== $profile->email
                || empty($account->email_verified_at)
                || (property_exists($account, 'verification_status')
                    && !in_array($account->verification_status, ['verified', 'approved'], true))) {
                return response()->json(['error' => 'Verified director identity unavailable'], 409);
            }
            // Locking the verified user's row also prevents concurrent school
            // appointments from accepting the same identity in two schools.
            if (DB::table('school_management_assignments')->where('user_id', $account->id)
                ->where('role', 'director')->whereNull('ends_at')->exists()) {
                return response()->json(['error' => 'Director already has an active school appointment'], 409);
            }

            $actorId = (int) $request->attributes->get('jwt_user')->id;
            if ($current) {
                DB::table('institution_director_assignments')->where('id', $current->id)
                    ->whereNull('ended_on')->update([
                        'ended_on' => $data['starts_on'], 'ended_by' => $actorId,
                        'updated_at' => now(),
                    ]);
                DB::table('school_management_assignments')->where('id', $oldOperational->id)
                    ->whereNull('ends_at')->update(['ends_at' => now(), 'updated_at' => now()]);
                \App\Support\SchoolDirectorSession::revoke((int) $oldOperational->user_id);
            }

            // Actual privilege starts now, not at a caller-supplied backdated
            // effective date. Directory history tracks the requested date.
            DB::table('school_management_assignments')->insert([
                'school_id' => $school, 'user_id' => $account->id,
                'role' => 'director', 'appointed_by' => $actorId,
                'starts_at' => now(), 'ends_at' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $id = DB::table('institution_director_assignments')->insertGetId([
                'school_id' => $school, 'director_id' => $profile->id,
                'starts_on' => $data['starts_on'], 'ended_on' => null,
                'appointed_by' => $actorId, 'ended_by' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);

            return response()->json([
                'assignment' => $this->assignment(DB::table('institution_director_assignments')->find($id)),
            ], 201);
        }, 3);
    }

    public function endAssignment(Request $request, string $organizationSlug, int $school, int $assignment): JsonResponse
    {
        if (!$this->authorized($request)) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->schoolWithinOrganization($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'School not found'], 404);
        }
        $data = Validator::make($request->all(), [
            'ended_on' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            'expected_director_id' => ['required', 'integer', 'min:1'],
        ])->validate();

        return DB::transaction(function () use ($request, $organizationSlug, $school, $assignment, $data) {
            $schoolRow = DB::table('schools')->where('id', $school)
                ->where('organization_id', $request->attributes->get('organization')->id)
                ->where('is_active', true)->lockForUpdate()->first();
            if (!$schoolRow || !$this->schoolWithinOrganization($request, $organizationSlug, $school)) {
                return response()->json(['error' => 'School not found'], 404);
            }
            if (!$this->authorized($request)) return response()->json(['error' => 'Forbidden'], 403);

            $target = DB::table('institution_director_assignments')
                ->where('school_id', $school)->where('id', $assignment)
                ->lockForUpdate()->first();
            if (!$target) return response()->json(['error' => 'Assignment not found'], 404);
            if ($target->ended_on !== null || (int) $target->director_id !== (int) $data['expected_director_id']) {
                return response()->json(['error' => 'Director assignment changed; refresh first'], 409);
            }
            if ($data['ended_on'] < $target->starts_on) {
                return response()->json(['error' => 'End date precedes appointment'], 422);
            }
            $current = DB::table('institution_director_assignments')->where('school_id', $school)
                ->whereNull('ended_on')->lockForUpdate()->first();
            if (!$current || (int) $current->id !== (int) $assignment) {
                return response()->json(['error' => 'Director assignment changed; refresh first'], 409);
            }
            [$consistent, $operational] = $this->currentOperationalAppointment($school, $current);
            if (!$consistent) {
                return response()->json(['error' => 'Director appointment state needs reconciliation'], 409);
            }

            $actorId = (int) $request->attributes->get('jwt_user')->id;
            DB::table('institution_director_assignments')->where('id', $assignment)
                ->whereNull('ended_on')->update([
                    'ended_on' => $data['ended_on'], 'ended_by' => $actorId,
                    'updated_at' => now(),
                ]);
            DB::table('school_management_assignments')->where('id', $operational->id)
                ->whereNull('ends_at')->update(['ends_at' => now(), 'updated_at' => now()]);
            \App\Support\SchoolDirectorSession::revoke((int) $operational->user_id);

            return response()->json([
                'assignment' => $this->assignment(
                    DB::table('institution_director_assignments')->where('id', $assignment)->first()
                ),
            ]);
        }, 3);
    }

    /**
     * Fail closed if imported directory history no longer mirrors the
     * operational assignment. This also permits ending legacy (non-dedicated)
     * director appointments without promoting unrelated accounts.
     *
     * @return array{bool, ?object}
     */
    private function currentOperationalAppointment(int $school, ?object $current): array
    {
        $active = DB::table('school_management_assignments')
            ->where('school_id', $school)->where('role', 'director')
            ->whereNull('ends_at')->lockForUpdate()->limit(2)->get();
        if ($current === null) return [$active->isEmpty(), null];
        if ($active->count() !== 1) return [false, null];

        $live = $active->first();
        $profile = DB::table('institution_director_profiles')
            ->where('id', $current->director_id)->where('school_id', $school)->first();
        $account = DB::table('users')->where('id', $live->user_id)->first();
        if (!$profile || !$account
            || ($profile->identity_user_id !== null
                && (int) $profile->identity_user_id !== (int) $live->user_id)
            || mb_strtolower(trim((string) $profile->email))
                !== mb_strtolower(trim((string) $account->email))) {
            return [false, null];
        }
        return [true, $live];
    }

    private function authorized(Request $request): bool
    {
        $actor = $request->attributes->get('jwt_user');
        $org = $request->attributes->get('organization');
        if (!$actor || !$org) return false;
        if (($actor->role ?? null) === 'admin') return true;
        if (($actor->role ?? null) !== 'institution') return false;
        // Re-check sensitive permissions beyond the organization membership
        // middleware. School admins cannot appoint or manage directors.
        return DB::table('organization_user')
            ->where('organization_id', $org->id)->where('user_id', $actor->id)
            ->where('is_active', true)->whereIn('role', ['owner', 'admin'])->exists();
    }

    private function schoolWithinOrganization(Request $request, string $slug, int $school): bool
    {
        $org = $request->attributes->get('organization');
        return $org && ($org->slug ?? null) === $slug
            && DB::table('organizations')->where('id', $org->id)->where('is_active', true)->exists()
            && DB::table('schools')->where('id', $school)->where('organization_id', $org->id)
                ->where('is_active', true)->exists();
    }

    private function validatedProfile(Request $request): array
    {
        $input = $request->all();
        foreach (['name', 'email', 'phone', 'qualification'] as $key) {
            if (isset($input[$key]) && is_string($input[$key])) $input[$key] = trim($input[$key]);
        }
        $data = Validator::make($input, [
            'name' => ['required', 'string', 'max:150'],
            'email' => ['required', 'email', 'max:190'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'qualification' => ['sometimes', 'nullable', 'string', 'max:255'],
            'experience_years' => ['required', 'integer', 'between:0,80'],
        ])->validate();
        $data['email'] = mb_strtolower($data['email']);
        $data['phone'] = $data['phone'] ?? '';
        $data['qualification'] = $data['qualification'] ?? '';
        return $data;
    }

    private function duplicateEmail(int $school, string $email, ?int $exceptId = null): bool
    {
        return DB::table('institution_director_profiles')
            ->where('school_id', $school)->whereRaw('LOWER(email) = ?', [$email])
            ->when($exceptId !== null, fn ($q) => $q->where('id', '!=', $exceptId))
            ->exists();
    }

    private function profile(object $p): array
    {
        return [
            'id' => (int) $p->id, 'school_id' => (int) $p->school_id,
            'name' => $p->name, 'email' => $p->email,
            'phone' => $p->phone, 'qualification' => $p->qualification,
            'experience_years' => (int) $p->experience_years,
        ];
    }

    private function assignment(object $a): array
    {
        return [
            'id' => (int) $a->id, 'school_id' => (int) $a->school_id,
            'director_id' => (int) $a->director_id,
            'starts_on' => $a->starts_on, 'ended_on' => $a->ended_on,
        ];
    }
}
