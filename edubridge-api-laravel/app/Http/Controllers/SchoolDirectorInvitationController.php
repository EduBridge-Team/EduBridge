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
        // Retired: an existing user account can never be promoted into a director.
        // New, standalone accounts are created through the invitation activation endpoint.
        return response()->json(['error' => 'Use dedicated director activation'], 410);
    }

}
