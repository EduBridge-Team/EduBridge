<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use App\Support\InstitutionDirectorDirectorySync;

class DedicatedSchoolDirectorController extends Controller
{
    public function activate(Request $request): JsonResponse
    {
        $validation = Validator::make($request->all(), [
            'token' => ['required', 'string', 'size:64'],
            'name' => ['required', 'string', 'max:150'],
            'password' => ['required', 'string', 'min:12', 'max:128', 'confirmed'],
        ]);
        if ($validation->fails()) return response()->json(['errors' => $validation->errors()], 422);
        $data = $validation->validated();
        $tokenHash = hash('sha256', $data['token']);

        try {
            return DB::transaction(function () use ($data, $tokenHash) {
                $candidate = DB::table('school_director_invitations')
                    ->where('token_hash', $tokenHash)->first();
                if (!$candidate) return response()->json(['error' => 'Invitation unavailable'], 404);
                $school = DB::table('schools')->where('id', $candidate->school_id)
                    ->where('is_active', true)->lockForUpdate()->first();
                if (!$school || ($school->organization_id !== null
                    && !DB::table('organizations')->where('id', $school->organization_id)
                        ->where('is_active', true)->exists())) {
                    return response()->json(['error' => 'School unavailable'], 403);
                }
                $invite = DB::table('school_director_invitations')
                    ->where('id', $candidate->id)->lockForUpdate()->first();
                if (!$invite || $invite->accepted_at || $invite->revoked_at
                    || now()->greaterThanOrEqualTo($invite->expires_at)) {
                    return response()->json(['error' => 'Invitation expired or used'], 409);
                }
                // Reject every existing user identity, including parent, teacher, specialist,
                // student, admin or another director. Email identity may never be reused.
                if (DB::table('users')->whereRaw('LOWER(email) = ?', [mb_strtolower($invite->email)])->exists()) {
                    return response()->json(['error' => 'Director requires a new, unused email'], 409);
                }
                $active = DB::table('school_management_assignments')
                    ->where('school_id', $school->id)->where('role', 'director')
                    ->whereNull('ends_at')->first();
                if (($active ? (int) $active->id : null)
                    !== ($invite->expected_director_assignment_id === null
                        ? null : (int) $invite->expected_director_assignment_id)) {
                    return response()->json(['error' => 'Director assignment changed'], 409);
                }
                $passwordHash = password_hash($data['password'], PASSWORD_BCRYPT);
                $user = [
                    'name' => trim($data['name']),
                    'email' => mb_strtolower($invite->email),
                    'role' => 'school_director',
                    'password_hash' => $passwordHash,
                ];
                if (Schema::hasColumn('users', 'password')) $user['password'] = $passwordHash;
                if (Schema::hasColumn('users', 'email_verified_at')) $user['email_verified_at'] = now();
                if (Schema::hasColumn('users', 'verification_status')) $user['verification_status'] = 'verified';
                if (Schema::hasColumn('users', 'created_at')) $user['created_at'] = now();
                if (Schema::hasColumn('users', 'updated_at')) $user['updated_at'] = now();
                $userId = DB::table('users')->insertGetId($user);
                if ($active) DB::table('school_management_assignments')
                    ->where('id', $active->id)->update(['ends_at' => now(), 'updated_at' => now()]);
                DB::table('school_management_assignments')->insert([
                    'school_id' => $school->id, 'user_id' => $userId,
                    'role' => 'director', 'appointed_by' => $invite->invited_by,
                    'starts_at' => now(), 'ends_at' => null,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                // In the same transaction as the verified dedicated-account
                // appointment, mirror the current/historical profile directory.
                // This never creates login rights from a draft profile.
                InstitutionDirectorDirectorySync::activated($school, $invite, (int) $userId, $data['name']);
                DB::table('school_director_invitations')->where('id', $invite->id)
                    ->update(['accepted_at' => now(), 'updated_at' => now()]);
                return response()->json(['activated' => true, 'school_id' => (int) $school->id]);
            }, 3);
        } catch (\Illuminate\Database\QueryException $error) {
            report($error);
            return response()->json(['error' => 'Unable to activate director account'], 503);
        }
    }
}
