<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
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
            'email' => ['required', 'email', 'max:190'],
            'password' => ['required', 'string', 'min:8', 'max:128', 'confirmed'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $data = $validation->validated();
        $name = trim($data['name']);
        $email = mb_strtolower(trim($data['email']));
        if ($name === '') {
            return response()->json(['errors' => ['name' => ['Required']]], 422);
        }
        if (DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->exists()) {
            return response()->json(['error' => 'Duplicate account'], 409);
        }

        try {
            [$schoolId, $userId] = DB::transaction(function () use ($data, $name, $email, $organizationId) {
                $user = ['name' => $name, 'email' => $email, 'role' => 'school',
                    'created_at' => now(), 'updated_at' => now()];
                $hash = password_hash($data['password'], PASSWORD_BCRYPT);
                foreach (['password_hash', 'password'] as $column) {
                    if (Schema::hasColumn('users', $column)) {
                        $user[$column] = $hash;
                    }
                }
                if (Schema::hasColumn('users', 'phone')) {
                    $user['phone'] = $data['phone'] ?? null;
                }
                if (Schema::hasColumn('users', 'verification_status')) {
                    $user['verification_status'] = 'pending';
                }
                $userId = DB::table('users')->insertGetId($user);
                $schoolId = DB::table('schools')->insertGetId([
                    'organization_id' => $organizationId, 'name' => $name,
                    'slug' => 'school-' . Str::lower(Str::random(24)),
                    'address' => $data['address'] ?? null,
                    'phone' => $data['phone'] ?? null,
                    'email' => $email, 'settings' => '{}', 'is_active' => true,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                DB::table('school_accounts')->insert([
                    'school_id' => $schoolId, 'user_id' => $userId,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                return [$schoolId, $userId];
            });
            // Provisioning is not proof of mailbox ownership. Send the same
            // verification link as ordinary registration, after commit.
            try {
                $account = DB::table('users')->find($userId);
                app(\App\Support\EmailVerificationSender::class)->send($account);
            } catch (\\Throwable $mailError) {
                report($mailError);
                // The created account can request verification again.
            }
            return response()->json([
                'school' => ['id' => $schoolId, 'name' => $name, 'organization_id' => $organizationId],
                'account' => ['id' => $userId, 'email' => $email, 'role' => 'school'],
            ], 201);
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
