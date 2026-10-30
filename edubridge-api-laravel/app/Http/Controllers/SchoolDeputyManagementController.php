<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SchoolDeputyManagementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $school = $this->directorSchool($request);
        if (!$school) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }
        $deputies = DB::table('school_management_assignments as assignment')
            ->join('users as user', 'user.id', '=', 'assignment.user_id')
            ->where('assignment.school_id', $school->id)
            ->where('assignment.role', 'deputy_director')
            ->whereNull('assignment.ends_at')
            ->select('assignment.id', 'user.id as user_id', 'user.name', 'user.email', 'assignment.starts_at')
            ->orderBy('assignment.id')->get();
        return response()->json(['school_id' => (int) $school->id, 'deputies' => $deputies]);
    }

    public function store(Request $request): JsonResponse
    {
        $validation = Validator::make($request->all(), [
            'user_email' => ['required', 'email', 'max:190'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $email = mb_strtolower(trim($validation->validated()['user_email']));
        return DB::transaction(function () use ($request, $email) {
            $school = $this->directorSchool($request, true);
            if (!$school) {
                return response()->json(['error' => 'School access is unavailable'], 403);
            }
            $user = DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->first();
            if (!$user || !filter_var($user->email, FILTER_VALIDATE_EMAIL)
                || str_ends_with(strtolower($user->email), '.edubridge')
                || (property_exists($user, 'verification_status')
                    && !in_array($user->verification_status, ['verified', 'approved'], true))) {
                return response()->json(['error' => 'Deputy requires an existing verified personal account'], 422);
            }
            if ((int) $user->id === (int) $request->attributes->get('jwt_user')->id) {
                return response()->json(['error' => 'Director cannot appoint self as deputy'], 422);
            }
            $existing = DB::table('school_management_assignments')
                ->where('school_id', $school->id)->where('user_id', $user->id)
                ->where('role', 'deputy_director')->whereNull('ends_at')->first();
            if ($existing) {
                return response()->json(['school_id' => (int) $school->id,
                    'assignment_id' => (int) $existing->id, 'unchanged' => true]);
            }
            $id = DB::table('school_management_assignments')->insertGetId([
                'school_id' => $school->id, 'user_id' => $user->id,
                'role' => 'deputy_director', 'appointed_by' => $request->attributes->get('jwt_user')->id,
                'starts_at' => now(), 'ends_at' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['school_id' => (int) $school->id,
                'assignment_id' => (int) $id, 'user_id' => (int) $user->id], 201);
        }, 3);
    }

    public function revoke(Request $request, int $assignment): JsonResponse
    {
        return DB::transaction(function () use ($request, $assignment) {
            $school = $this->directorSchool($request, true);
            if (!$school) {
                return response()->json(['error' => 'School access is unavailable'], 403);
            }
            $changed = DB::table('school_management_assignments')
                ->where('id', $assignment)->where('school_id', $school->id)
                ->where('role', 'deputy_director')->whereNull('ends_at')
                ->update(['ends_at' => now(), 'updated_at' => now()]);
            if (!$changed) {
                return response()->json(['error' => 'Active deputy assignment not found'], 404);
            }
            return response()->json(['revoked' => true, 'assignment_id' => $assignment]);
        }, 3);
    }

    private function directorSchool(Request $request, bool $lock = false): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return null;
        }
        $query = DB::table('school_management_assignments as assignment')
            ->join('schools as school', 'school.id', '=', 'assignment.school_id')
            ->where('assignment.user_id', $actor->id)
            ->where('assignment.role', 'director')
            ->whereNull('assignment.ends_at')
            ->where('school.is_active', true)
            ->select('school.id', 'school.organization_id')->limit(2);
        $schools = $lock ? $query->lockForUpdate()->get() : $query->get();
        if ($schools->count() !== 1) {
            return null;
        }
        $school = $schools->first();
        if ($school->organization_id !== null && !DB::table('organizations')
            ->where('id', $school->organization_id)->where('is_active', true)->exists()) {
            return null;
        }
        return $school;
    }
}
