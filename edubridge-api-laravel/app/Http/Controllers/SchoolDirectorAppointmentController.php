<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SchoolDirectorAppointmentController extends Controller
{
    public function appoint(Request $request, int $school): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'Forbidden'], 403);
        }

        $validation = Validator::make($request->all(), [
            'director_email' => ['required', 'email', 'max:190'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $email = mb_strtolower(trim($validation->validated()['director_email']));

        return DB::transaction(function () use ($actor, $school, $email) {
            $schoolRecord = DB::table('schools')->where('id', $school)
                ->where('is_active', true)->lockForUpdate()->first();
            if (!$schoolRecord) {
                return response()->json(['error' => 'School not found'], 404);
            }
            if (!$this->mayAppoint($actor, $schoolRecord)) {
                return response()->json(['error' => 'Forbidden'], 403);
            }

            // Only an existing, verified personal email identity may become director.
            $director = DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->first();
            if (!$director || !filter_var($director->email, FILTER_VALIDATE_EMAIL)
                || str_ends_with(strtolower($director->email), '.edubridge')) {
                return response()->json(['error' => 'Director must have an existing real-email account'], 422);
            }
            if (property_exists($director, 'verification_status')
                && !in_array($director->verification_status, ['verified', 'approved'], true)) {
                return response()->json(['error' => 'Director email is not verified'], 422);
            }

            $active = DB::table('school_management_assignments')
                ->where('school_id', $school)->where('role', 'director')
                ->whereNull('ends_at')->first();
            if ($active && (int) $active->user_id === (int) $director->id) {
                return response()->json(['school_id' => $school,
                    'director_user_id' => (int) $director->id, 'unchanged' => true]);
            }
            if ($active) {
                DB::table('school_management_assignments')->where('id', $active->id)
                    ->update(['ends_at' => now(), 'updated_at' => now()]);
            }
            DB::table('school_management_assignments')->insert([
                'school_id' => $school, 'user_id' => $director->id,
                'role' => 'director', 'appointed_by' => $actor->id,
                'starts_at' => now(), 'ends_at' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['school_id' => $school,
                'director_user_id' => (int) $director->id,
                'previous_director_user_id' => $active ? (int) $active->user_id : null]);
        }, 3);
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
