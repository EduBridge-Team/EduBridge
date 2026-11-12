<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class SchoolDirectStudentController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || ($actor->role ?? null) === 'school') {
            return response()->json(['error' => 'Active school director required'], 403);
        }

        $validation = Validator::make($request->all(), [
            'expected_school_id' => ['required', 'integer', 'min:1'],
            'name' => ['required', 'string', 'max:100'],
            'username' => ['required', 'string', 'regex:/^[a-z0-9][a-z0-9._-]{1,63}$/D'],
            'student_number' => ['required', 'string', 'regex:/^[A-Za-z0-9][A-Za-z0-9_-]{2,39}$/D'],
            'section_id' => ['required', 'integer', 'min:1'],
            'password' => ['required', 'string', 'min:12', 'max:128'],
            'school_authorized' => ['accepted'],
            'child_id' => ['prohibited'],
            'parent_id' => ['prohibited'],
            'role' => ['prohibited'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $data = $validation->validated();
        $name = trim($data['name']);
        if ($name === '') {
            return response()->json(['errors' => ['name' => ['Name required']]], 422);
        }
        $studentNumber = strtoupper($data['student_number']);

        if (!Schema::hasTable('school_direct_student_admissions')
            || !Schema::hasTable('student_account_links')
            || !Schema::hasTable('school_internal_identities')
            || !Schema::hasTable('children')
            || !Schema::hasColumn('users', 'email_verified_at')) {
            return response()->json(['error' => 'Direct student enrollment schema unavailable'], 503);
        }

        $passwordColumns = array_values(array_filter(['password_hash', 'password'],
            fn (string $column) => Schema::hasColumn('users', $column)));
        if (!$passwordColumns) {
            return response()->json(['error' => 'Password storage unavailable'], 503);
        }

        try {
            return DB::transaction(function () use ($request, $actor, $data, $name, $studentNumber, $passwordColumns) {
                $school = SchoolAdministration::directorSchool($request, true);
                if (!$school) {
                    return response()->json(['error' => 'Active school director required'], 403);
                }
                // Institution schools may have regulated admissions and review steps.
                // Never bypass those workflows through direct account creation.
                if ($school->organization_id !== null) {
                    return response()->json(['error' => 'Direct enrollment is limited to independent schools'], 403);
                }
                if (!$school->internal_domain || !$school->internal_domain_confirmed_at) {
                    return response()->json(['error' => 'Confirm the internal domain first'], 409);
                }

                // Lock only a section in the director's school, in its current
                // academic year. This serializes concurrent capacity checks.
                $section = DB::table('sections')
                    ->where('id', $data['section_id'])
                    ->whereIn('grade_id', DB::table('grades')
                        ->where('school_id', $school->id)->where('is_active', true)->select('id'))
                    ->whereIn('academic_year_id', DB::table('academic_years')
                        ->where('school_id', $school->id)->where('is_current', true)->select('id'))
                    ->lockForUpdate()->first(['id', 'capacity']);
                if (!$section) {
                    return response()->json(['error' => 'Current active section unavailable'], 422);
                }

                $email = $data['username'].'@'.$school->internal_domain;
                if (DB::table('users')->where('email', $email)->exists()
                    || DB::table('school_internal_identities')
                        ->where('school_id', $school->id)->where('username', $data['username'])->exists()
                    || DB::table('school_direct_student_admissions')
                        ->where('school_id', $school->id)->where('student_number', $studentNumber)->exists()) {
                    return response()->json(['error' => 'Student number or username already registered'], 409);
                }

                if ($section->capacity !== null
                    && DB::table('student_enrollments')
                        ->where('section_id', $section->id)->where('status', 'active')->count() >= (int) $section->capacity) {
                    return response()->json(['error' => 'Section is full'], 409);
                }

                // School-generated child records contain no invented guardian,
                // medical, or government-identity information. Verification
                // remains pending until separately reviewed.
                $child = ['name' => $name];
                if (Schema::hasColumn('children', 'organization_id')) $child['organization_id'] = null;
                if (Schema::hasColumn('children', 'status')) $child['status'] = 'pending';
                if (Schema::hasColumn('children', 'doc_verification_status')) $child['doc_verification_status'] = 'pending';
                if (Schema::hasColumn('children', 'created_at')) $child['created_at'] = now();
                $childId = DB::table('children')->insertGetId($child);

                $hash = password_hash($data['password'], PASSWORD_BCRYPT);
                $user = [
                    'name' => $name,
                    'email' => $email,
                    'role' => 'student',
                    'email_verified_at' => now(),
                ];
                foreach ($passwordColumns as $column) $user[$column] = $hash;
                // School-issued credentials are activated for student self-service.
                // This does not change the child document-verification status.
                if (Schema::hasColumn('users', 'verification_status')) $user['verification_status'] = 'verified';
                if (Schema::hasColumn('users', 'created_at')) $user['created_at'] = now();
                if (Schema::hasColumn('users', 'updated_at')) $user['updated_at'] = now();
                $userId = DB::table('users')->insertGetId($user);

                $enrollmentId = DB::table('student_enrollments')->insertGetId([
                    'child_id' => $childId,
                    'section_id' => $section->id,
                    'status' => 'active',
                    'enrolled_on' => now()->toDateString(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                DB::table('school_internal_identities')->insert([
                    'school_id' => $school->id,
                    'user_id' => $userId,
                    'username' => $data['username'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                DB::table('student_account_links')->insert([
                    'user_id' => $userId,
                    'child_id' => $childId,
                    'school_id' => $school->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                DB::table('school_direct_student_admissions')->insert([
                    'school_id' => $school->id,
                    'child_id' => $childId,
                    'student_number' => $studentNumber,
                    'created_by' => $actor->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                return response()->json([
                    'school_id' => (int) $school->id,
                    'child_id' => (int) $childId,
                    'user_id' => (int) $userId,
                    'enrollment_id' => (int) $enrollmentId,
                    'section_id' => (int) $section->id,
                    'student_number' => $studentNumber,
                    'login_identifier' => $email,
                    'role' => 'student',
                ], 201);
            }, 3);
        } catch (QueryException $exception) {
            if (in_array((string) $exception->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Student number or username already registered'], 409);
            }
            throw $exception;
        }
    }
}
