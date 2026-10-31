<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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

    private function create(Request $request, ?int $organizationId): JsonResponse
    {
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
