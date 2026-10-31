<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use App\Support\SchoolDirectorInvitations;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolDirectorInvitationController extends Controller
{
    public function index(Request $request, int $school): JsonResponse
    {
        $record = DB::table('schools')->find($school);
        if (!$record || !SchoolAdministration::mayAppoint($request->attributes->get('jwt_user'), $record)) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        return response()->json(['invitations' => DB::table('school_director_invitations')->where('school_id', $school)
            ->orderByDesc('id')->limit(100)->get(['id', 'email', 'expires_at', 'accepted_at', 'revoked_at', 'created_at'])]);
    }

    public function store(Request $request, int $school): JsonResponse
    {
        return DB::transaction(function () use ($request, $school) {
            $record = DB::table('schools')->where('id', $school)->where('is_active', true)->lockForUpdate()->first();
            if (!$record || !SchoolAdministration::mayAppoint($request->attributes->get('jwt_user'), $record)) {
                return response()->json(['error' => 'Forbidden'], 403);
            }
            $data = $request->validate(['director_email' => ['required', 'email', 'max:190']]);
            $email = mb_strtolower(trim($data['director_email']));
            if (str_ends_with($email, '.edubridge')) return response()->json(['error' => 'Personal email required'], 422);
            return response()->json(['invitation' => SchoolDirectorInvitations::issue($record, $email, $request->attributes->get('jwt_user')->id)], 201);
        }, 3);
    }

    public function revoke(Request $request, int $school, int $invitation): JsonResponse
    {
        return DB::transaction(function () use ($request, $school, $invitation) {
            $record = DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            if (!$record || !SchoolAdministration::mayAppoint($request->attributes->get('jwt_user'), $record)) {
                return response()->json(['error' => 'Forbidden'], 403);
            }
            $count = DB::table('school_director_invitations')->where('id', $invitation)->where('school_id', $school)
                ->whereNull('accepted_at')->whereNull('revoked_at')->update(['revoked_at' => now(), 'updated_at' => now()]);
            return response()->json(['revoked' => (bool) $count], $count ? 200 : 404);
        }, 3);
    }

    public function accept(Request $request): JsonResponse
    {
        $data = $request->validate(['token' => ['required', 'string', 'size:64'], 'preview' => ['sometimes', 'boolean']]);
        return DB::transaction(function () use ($request, $data) {
            $candidate = DB::table('school_director_invitations')->where('token_hash', hash('sha256', $data['token']))->first();
            if (!$candidate) return response()->json(['error' => 'Invitation unavailable'], 404);
            // Same lock order as direct appointments: school, then user, then invitation.
            $school = DB::table('schools')->where('id', $candidate->school_id)->where('is_active', true)->lockForUpdate()->first();
            $actor = $request->attributes->get('jwt_user');
            if (!$school || !$actor) return response()->json(['error' => 'Forbidden'], 403);
            if ($school->organization_id !== null && !DB::table('organizations')->where('id', $school->organization_id)->where('is_active', true)->exists()) {
                return response()->json(['error' => 'Forbidden'], 403);
            }
            $user = DB::table('users')->where('id', $actor->id)->lockForUpdate()->first();
            if (!$user || empty($user->email_verified_at) || ($user->role ?? null) === 'school'
                || str_ends_with(strtolower($user->email), '.edubridge')
                || mb_strtolower($user->email) !== $candidate->email) {
                return response()->json(['error' => 'Verified invited mailbox required'], 403);
            }
            $invite = DB::table('school_director_invitations')->where('id', $candidate->id)->lockForUpdate()->first();
            if ($invite->accepted_at || $invite->revoked_at || now()->greaterThanOrEqualTo($invite->expires_at)) {
                return response()->json(['error' => 'Invitation expired or already used'], 409);
            }
            $active = DB::table('school_management_assignments')->where('school_id', $school->id)
                ->where('role', 'director')->whereNull('ends_at')->first();
            if (($active ? (int) $active->id : null) !== ($invite->expected_director_assignment_id === null ? null : (int) $invite->expected_director_assignment_id)) {
                return response()->json(['error' => 'Director assignment changed'], 409);
            }
            if (DB::table('school_management_assignments')->where('user_id', $user->id)->where('role', 'director')
                ->whereNull('ends_at')->where('school_id', '!=', $school->id)->exists()) {
                return response()->json(['error' => 'Director already assigned'], 409);
            }
            if ($data['preview'] ?? false) {
                return response()->json(['school' => ['id' => (int) $school->id, 'name' => $school->name], 'email' => $invite->email, 'expires_at' => $invite->expires_at]);
            }
            if ($active) DB::table('school_management_assignments')->where('id', $active->id)->update(['ends_at' => now(), 'updated_at' => now()]);
            DB::table('school_management_assignments')->insert([
                'school_id' => $school->id, 'user_id' => $user->id, 'role' => 'director',
                'appointed_by' => $invite->invited_by, 'starts_at' => now(), 'ends_at' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            DB::table('school_director_invitations')->where('id', $invite->id)->update(['accepted_at' => now(), 'updated_at' => now()]);
            DB::table('school_administration_events')->insert([
                'school_id' => $school->id, 'actor_id' => $user->id, 'action' => 'director_invitation_accepted',
                'subject_id' => $user->id, 'created_at' => now(),
            ]);
            return response()->json(['accepted' => true, 'school_id' => (int) $school->id]);
        }, 3);
    }
}
