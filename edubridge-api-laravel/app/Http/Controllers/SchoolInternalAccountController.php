<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class SchoolInternalAccountController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validation = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:190'],
            'username' => ['required', 'string', 'regex:/^[a-z0-9][a-z0-9._-]{1,63}$/D'],
            'role' => ['required', 'in:teacher,student,staff'],
            'child_id' => ['required_if:role,student', 'nullable', 'integer', 'min:1'],
            'password' => ['required', 'string', 'min:12', 'max:128'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }

        $input = $validation->validated();
        if (trim($input['name']) === '') return response()->json(['error' => 'Name required'], 422);
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }

        if (!Schema::hasTable('school_internal_identities')
            || !Schema::hasColumn('users', 'email_verified_at')) {
            return response()->json(['error' => 'School identity schema is unavailable'], 503);
        }

        $passwordColumn = Schema::hasColumn('users', 'password_hash')
            ? 'password_hash' : (Schema::hasColumn('users', 'password') ? 'password' : null);
        if ($passwordColumn === null) {
            return response()->json(['error' => 'Password storage is unavailable'], 503);
        }

        try {
            return DB::transaction(function () use ($request, $actor, $input, $passwordColumn) {
                $schools = DB::table('school_management_assignments as assignment')
                    ->join('schools as school', 'school.id', '=', 'assignment.school_id')
                    ->where('assignment.user_id', $actor->id)
                    ->where('assignment.role', 'director')
                    ->whereNull('assignment.ends_at')
                    ->where('school.is_active', true)
                    ->select('school.id', 'school.organization_id', 'school.internal_domain',
                        'school.internal_domain_confirmed_at')
                    ->limit(2)->lockForUpdate()->get();
                if ($schools->count() !== 1) {
                    return response()->json(['error' => 'School access is unavailable'], 403);
                }
                $school = $schools->first();
                if ($request->has('expected_school_id') && (int) $request->input('expected_school_id') !== (int) $school->id) return response()->json(['error' => 'School context changed'], 409);
                if ($school->organization_id !== null && !DB::table('organizations')
                    ->where('id', $school->organization_id)->where('is_active', true)->exists()) {
                    return response()->json(['error' => 'School access is unavailable'], 403);
                }
                if (!$school->internal_domain_confirmed_at || !$school->internal_domain) {
                    return response()->json(['error' => 'Internal domain must be confirmed'], 409);
                }

                if ($input['role'] === 'student') {
                    if (!Schema::hasTable('student_account_links')) {
                        return response()->json(['error' => 'Student account linking is unavailable'], 503);
                    }
                    // A student login must belong to an existing enrolled child in this school.
                    $enrolled = DB::table('student_enrollments as e')
                        ->join('sections as s', 's.id', '=', 'e.section_id')
                        ->join('grades as g', 'g.id', '=', 's.grade_id')
                        ->where('e.child_id', $input['child_id'])
                        ->where('g.school_id', $school->id)
                        ->where('e.status', 'active')->exists();
                    if (!$enrolled) {
                        return response()->json(['error' => 'Student is not actively enrolled at this school'], 422);
                    }
                    if (DB::table('student_account_links')->where('child_id', $input['child_id'])->exists()) {
                        return response()->json(['error' => 'This student already has a login account'], 409);
                    }
                }

                $email = $input['username'].'@'.$school->internal_domain;
                if (DB::table('users')->where('email', $email)->exists()
                    || DB::table('school_internal_identities')
                        ->where('school_id', $school->id)->where('username', $input['username'])->exists()) {
                    return response()->json(['error' => 'Internal username is already taken'], 409);
                }

                $hash = password_hash($input['password'], PASSWORD_BCRYPT);
                $user = [
                    'name' => trim($input['name']),
                    'email' => $email,
                    'role' => $input['role'],
                    $passwordColumn => $hash,
                    'email_verified_at' => now(),
                ];
                if (Schema::hasColumn('users', 'password')
                    && Schema::hasColumn('users', 'password_hash')) {
                    $user['password'] = $hash;
                    $user['password_hash'] = $hash;
                }
                if (Schema::hasColumn('users', 'verification_status')) {
                    $user['verification_status'] = 'verified';
                }
                if (Schema::hasColumn('users', 'created_at')) {
                    $user['created_at'] = now();
                    $user['updated_at'] = now();
                }
                $userId = DB::table('users')->insertGetId($user);
                DB::table('school_internal_identities')->insert([
                    'school_id' => $school->id, 'user_id' => $userId,
                    'username' => $input['username'], 'created_at' => now(), 'updated_at' => now(),
                ]);
                if ($input['role'] === 'student') {
                    DB::table('student_account_links')->insert([
                        'user_id' => $userId,
                        'child_id' => $input['child_id'],
                        'school_id' => $school->id,
                        'created_at' => now(), 'updated_at' => now(),
                    ]);
                }
                return response()->json([
                    'school_id' => (int) $school->id,
                    'user_id' => (int) $userId,
                    'username' => $input['username'],
                    'login_identifier' => $email,
                    'role' => $input['role'],
                ], 201);
            }, 3);
        } catch (QueryException $e) {
            if (in_array((string) $e->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Internal username is already taken'], 409);
            }
            throw $e;
        }
    }
}
