<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Support\SchoolOfficialActivation;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class SchoolProvisionController extends Controller
{
    public function independent(Request $request): JsonResponse
    {
        if (($request->attributes->get('jwt_user')->role ?? null) !== 'admin') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        return $this->create($request, null);
    }

    public function affiliated(Request $request, string $organizationSlug): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        $organization = $request->attributes->get('organization');
        if (!$actor || !$organization || ($actor->role ?? null) !== 'institution') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $authorized = DB::table('organization_user')
            ->where('organization_id', $organization->id)
            ->where('user_id', $actor->id)
            ->where('is_active', true)
            ->whereIn('role', ['owner', 'admin'])->exists();
        if (!$authorized) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        return $this->create($request, (int) $organization->id);
    }

    private function createOfficial(Request $request, ?int $organizationId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:150'],
            'school_email' => ['required', 'email', 'max:190'],
            'director_email' => ['nullable', 'email', 'max:190', 'required_if:invite_director,true'],
            'invite_director' => ['sometimes', 'boolean'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);
        $data = $validator->validated();
        $name = trim($data['name']);
        $schoolEmail = mb_strtolower(trim($data['school_email']));
        $directorEmail = mb_strtolower(trim($data['director_email'] ?? ''));
        $invite = (bool) ($data['invite_director'] ?? false);

        if ($name === '' || str_ends_with($schoolEmail, '.edubridge')) {
            return response()->json(['errors' => ['school_email' => ['Valid official email required']]], 422);
        }
        if ($directorEmail !== '' && ($directorEmail === $schoolEmail || str_ends_with($directorEmail, '.edubridge'))) {
            return response()->json(['errors' => ['director_email' => ['Distinct personal email required']]], 422);
        }

        try {
            return DB::transaction(function () use ($request, $organizationId, $name, $schoolEmail, $directorEmail, $invite, $data) {
                if (DB::table('users')->whereRaw('LOWER(email) = ?', [$schoolEmail])->exists()
                    || DB::table('schools')->whereRaw('LOWER(email) = ?', [$schoolEmail])->exists()) {
                    return response()->json(['error' => 'Official school email already used'], 409);
                }

                $director = null;
                if ($directorEmail !== '' && !$invite) {
                    $director = DB::table('users')->whereRaw('LOWER(email) = ?', [$directorEmail])->lockForUpdate()->first();
                    if (!$director || in_array($director->role, ['school', 'school_identity'], true)
                        || empty($director->email_verified_at)
                        || (property_exists($director, 'verification_status')
                            && !in_array($director->verification_status, ['verified', 'approved'], true))) {
                        return response()->json(['error' => 'Existing verified director account required'], 422);
                    }
                    if (DB::table('school_management_assignments')->where('user_id', $director->id)
                        ->where('role', 'director')->whereNull('ends_at')->exists()) {
                        return response()->json(['error' => 'Director already has an active school assignment'], 409);
                    }
                }

                $schoolId = DB::table('schools')->insertGetId([
                    'organization_id' => $organizationId,
                    'name' => $name,
                    'slug' => 'school-' . Str::lower(Str::random(24)),
                    'address' => $data['address'] ?? null,
                    'phone' => $data['phone'] ?? null,
                    'email' => $schoolEmail,
                    'settings' => '{}',
                    'is_active' => true,
                    'created_at' => now(), 'updated_at' => now(),
                ]);

                // Random unusable-by-operator password until the mailbox
                // owner sets one through the single-use activation link.
                $randomHash = password_hash(Str::random(64), PASSWORD_BCRYPT, ['cost' => 10]);
                $account = [
                    'name' => $name, 'email' => $schoolEmail,
                    'role' => 'school_identity',
                    'email_verified_at' => null,
                    'created_at' => now(), 'updated_at' => now(),
                ];
                foreach (['password', 'password_hash'] as $column) {
                    if (Schema::hasColumn('users', $column)) $account[$column] = $randomHash;
                }
                $userId = DB::table('users')->insertGetId($account);
                DB::table('school_accounts')->insert([
                    'school_id' => $schoolId, 'user_id' => $userId,
                    'created_at' => now(), 'updated_at' => now(),
                ]);

                $school = DB::table('schools')->find($schoolId);
                SchoolOfficialActivation::issue($school);
                $result = [
                    'school' => ['id' => $schoolId, 'name' => $name, 'email' => $schoolEmail,
                        'organization_id' => $organizationId, 'activation_status' => 'pending'],
                    'account' => ['id' => $userId, 'email' => $schoolEmail, 'role' => 'school_identity'],
                ];
                if ($directorEmail !== '' && $invite) {
                    $result['invitation'] = \App\Support\SchoolDirectorInvitations::issue(
                        $school, $directorEmail, (int) $request->attributes->get('jwt_user')->id
                    );
                } elseif ($director) {
                    DB::table('school_management_assignments')->insert([
                        'school_id' => $schoolId, 'user_id' => $director->id,
                        'role' => 'director', 'appointed_by' => $request->attributes->get('jwt_user')->id,
                        'starts_at' => now(), 'ends_at' => null, 'created_at' => now(), 'updated_at' => now(),
                    ]);
                    $result['director'] = ['id' => (int) $director->id, 'email' => $directorEmail];
                }
                return response()->json($result, 201);
            }, 3);
        } catch (QueryException $e) {
            if (in_array((string) $e->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Duplicate account'], 409);
            }
            report($e);
        } catch (\Throwable $e) {
            report($e);
        }
        return response()->json(['error' => 'Could not provision school'], 500);
    }

    private function create(Request $request, ?int $organizationId): JsonResponse
    {
        // New clients use the official school mailbox. Older director-first
        // requests remain supported until all deployed clients are upgraded.
        if ($request->exists('school_email')) {
            return $this->createOfficial($request, $organizationId);
        }
        $validation = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:150'],
            'director_email' => ['required', 'email', 'max:190'],
            'invite_director' => ['sometimes', 'boolean'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $data = $validation->validated();
        $name = trim($data['name']);
        $email = mb_strtolower(trim($data['director_email']));
        if ($name === '') {
            return response()->json(['errors' => ['name' => ['Required']]], 422);
        }
        if (str_ends_with($email, '.edubridge')) {
            return response()->json(['error' => 'Director must use a personal email'], 422);
        }

        try {
            return DB::transaction(function () use ($request, $data, $name, $email, $organizationId) {
                $director = DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->lockForUpdate()->first();
                $invite = (bool) ($data['invite_director'] ?? false);
                if (!$invite && (!$director || ($director->role ?? null) === 'school'
                    || empty($director->email_verified_at)
                    || (property_exists($director, 'verification_status')
                        && !in_array($director->verification_status, ['verified', 'approved'], true)))) {
                    return response()->json(['error' => 'Existing verified director account required'], 422);
                }
                if (!$invite && DB::table('school_management_assignments')->where('user_id', $director->id)
                    ->where('role', 'director')->whereNull('ends_at')->exists()) {
                    return response()->json(['error' => 'Director already has an active school assignment'], 409);
                }
                $schoolId = DB::table('schools')->insertGetId([
                    'organization_id' => $organizationId,
                    'name' => $name,
                    'slug' => 'school-' . Str::lower(Str::random(24)),
                    'address' => $data['address'] ?? null,
                    'phone' => $data['phone'] ?? null,
                    'email' => $email,
                    'settings' => '{}',
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                if ($invite) {
                    $school = DB::table('schools')->find($schoolId);
                    return response()->json([
                        'school' => ['id' => $schoolId, 'name' => $name, 'organization_id' => $organizationId],
                        'invitation' => \App\Support\SchoolDirectorInvitations::issue($school, $email, $request->attributes->get('jwt_user')->id),
                    ], 201);
                }
                DB::table('school_management_assignments')->insert([
                    'school_id' => $schoolId,
                    'user_id' => $director->id,
                    'role' => 'director',
                    'appointed_by' => $request->attributes->get('jwt_user')->id,
                    'starts_at' => now(),
                    'ends_at' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                return response()->json([
                    'school' => ['id' => $schoolId, 'name' => $name, 'organization_id' => $organizationId],
                    'director' => ['id' => (int) $director->id, 'email' => $email],
                ], 201);
            }, 3);
        } catch (QueryException $e) {
            if (in_array((string) $e->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Duplicate account'], 409);
            }
            report($e);
        } catch (\Throwable $e) {
            report($e);
        }
        return response()->json(['error' => 'Could not provision school'], 500);
    }
}
