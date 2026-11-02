<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use App\Support\SchoolOfficialActivation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SchoolOfficialAccountController extends Controller
{
    public function activate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'size:64'],
            'password' => ['required', 'string', 'min:12', 'max:128', 'confirmed'],
        ]);

        return DB::transaction(function () use ($data) {
            $hash = hash('sha256', $data['token']);
            $candidate = DB::table('school_account_activation_tokens')->where('token_hash', $hash)->first();
            if (!$candidate) return response()->json(['error' => 'Activation link invalid or expired'], 422);

            $school = DB::table('schools')->where('id', $candidate->school_id)->lockForUpdate()->first();
            if (!$school || !$school->is_active) return response()->json(['error' => 'School unavailable'], 403);
            if ($school->organization_id !== null &&
                !DB::table('organizations')->where('id', $school->organization_id)->where('is_active', true)->exists()) {
                return response()->json(['error' => 'School unavailable'], 403);
            }

            $token = DB::table('school_account_activation_tokens')->where('school_id', $school->id)->lockForUpdate()->first();
            if (!$token || !hash_equals($token->token_hash, $hash) || $token->consumed_at ||
                now()->greaterThanOrEqualTo($token->expires_at)) {
                return response()->json(['error' => 'Activation link invalid or expired'], 422);
            }

            $account = DB::table('school_accounts as a')->join('users as u', 'u.id', '=', 'a.user_id')
                ->where('a.school_id', $school->id)->where('u.role', 'school_identity')->select('u.*')->first();
            if (!$account || mb_strtolower($account->email) !== mb_strtolower($school->email)) {
                return response()->json(['error' => 'School identity unavailable'], 403);
            }
            if ($account->email_verified_at) {
                return response()->json(['error' => 'School already activated'], 409);
            }

            $passwordHash = password_hash($data['password'], PASSWORD_BCRYPT, ['cost' => 10]);
            $updates = ['email_verified_at' => now(), 'updated_at' => now()];
            foreach (['password', 'password_hash'] as $column) {
                if (Schema::hasColumn('users', $column)) $updates[$column] = $passwordHash;
            }
            if (Schema::hasColumn('users', 'session_version')) {
                $updates['session_version'] = (int) ($account->session_version ?? 0) + 1;
            }
            DB::table('users')->where('id', $account->id)->update($updates);
            DB::table('school_account_activation_tokens')->where('school_id', $school->id)->update([
                'consumed_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['activated' => true, 'school' => ['id' => (int) $school->id, 'name' => $school->name]]);
        }, 3);
    }

    public function resend(Request $request, int $school): JsonResponse
    {
        return DB::transaction(function () use ($request, $school) {
            $record = DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            if (!$record || !SchoolAdministration::mayAppoint($request->attributes->get('jwt_user'), $record)) {
                return response()->json(['error' => 'Forbidden'], 403);
            }
            $account = DB::table('school_accounts as a')->join('users as u', 'u.id', '=', 'a.user_id')
                ->where('a.school_id', $school)->where('u.role', 'school_identity')->first(['u.email_verified_at']);
            if (!$account || $account->email_verified_at) {
                return response()->json(['error' => 'School not awaiting activation'], 409);
            }
            SchoolOfficialActivation::issue($record);
            return response()->json(['message' => 'Activation email requested']);
        }, 3);
    }

    public function profile(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || $actor->role !== 'school_identity') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $schools = DB::table('school_accounts as a')->join('schools as s', 's.id', '=', 'a.school_id')
            ->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('a.user_id', $actor->id)->where('s.is_active', true)
            ->where(fn ($q) => $q->whereNull('s.organization_id')->orWhere('o.is_active', true))
            ->select('s.id', 's.name', 's.email', 's.phone', 's.address', 's.organization_id')
            ->limit(2)->get();
        if ($schools->count() !== 1) return response()->json(['error' => 'School unavailable'], 403);
        return response()->json(['school' => $schools->first()]);
    }
}
