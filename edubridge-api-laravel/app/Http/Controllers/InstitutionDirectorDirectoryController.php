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
