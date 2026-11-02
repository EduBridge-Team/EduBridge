<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SchoolDirectorAppointmentController extends Controller
{
    public function show(Request $request, int $school): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $schoolRecord = DB::table('schools')->where('id', $school)
            ->where('is_active', true)->first();
        if (!$schoolRecord) {
            return response()->json(['error' => 'School not found'], 404);
        }
        if (!$this->mayAppoint($actor, $schoolRecord)) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $director = DB::table('school_management_assignments as assignment')
            ->join('users as user', 'user.id', '=', 'assignment.user_id')
            ->where('assignment.school_id', $school)
            ->where('assignment.role', 'director')
            ->whereNull('assignment.ends_at')
            ->select('user.id', 'user.name', 'user.email', 'assignment.starts_at')
            ->first();
        return response()->json(['school_id' => $school, 'director' => $director]);
    }

    public function appoint(Request $request, int $school): JsonResponse
    {
        // Direct assignment from an existing user account is intentionally forbidden.
        // Admins and institutions must invite a new mailbox through director-invitations.
        return response()->json([
            'error' => 'Direct appointment disabled. Invite a new director email instead.',
        ], 422);
    }

    private function mayAppoint(object $actor, object $school): bool
    {
        if (($actor->role ?? null) === 'admin') {
            return true;
        }
        if (($actor->role ?? null) !== 'institution' || $school->organization_id === null) {
            return false;
        }
        return DB::table('organizations')->where('id', $school->organization_id)
            ->where('is_active', true)->exists()
            && DB::table('organization_user')
                ->where('organization_id', $school->organization_id)
                ->where('user_id', $actor->id)
                ->where('is_active', true)->whereIn('role', ['owner', 'admin'])->exists();
    }
}
