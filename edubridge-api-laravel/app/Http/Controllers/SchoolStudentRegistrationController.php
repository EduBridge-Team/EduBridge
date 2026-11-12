<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class SchoolStudentRegistrationController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        if (!$request->attributes->get('jwt_user')) {
            return response()->json(['error' => 'School access is unavailable'], 403);
        }

        $validation = Validator::make($request->all(), [
            'expected_school_id' => ['required', 'integer', 'min:1'],
            'name' => ['required', 'string', 'max:100'],
            'username' => ['required', 'string', 'regex:/^[a-z0-9][a-z0-9._-]{1,63}$/D'],
            'password' => ['required', 'string', 'min:12', 'max:128'],
            'section_id' => ['required', 'integer', 'min:1'],
            'guardian_authorization_confirmed' => ['required', 'accepted'],
            // Do not let a school silently attach another person's child or
            // guardian, supply a foreign school, or declare documents verified.
            'child_id' => ['prohibited'],
            'parent_id' => ['prohibited'],
            'school_id' => ['prohibited'],
            'organization_id' => ['prohibited'],
            'role' => ['prohibited'],
            'verification_status' => ['prohibited'],
            'doc_verification_status' => ['prohibited'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $input = $validation->validated();
        $name = trim($input['name']);
        if ($name === '') return response()->json(['error' => 'Student name required'], 422);

        foreach (['children', 'student_enrollments', 'student_account_links',
            'school_internal_identities', 'school_administration_events'] as $table) {
            if (!Schema::hasTable($table)) {
                return response()->json(['error' => 'School student registration schema is unavailable'], 503);
            }
        }
        if (!Schema::hasColumn('users', 'email_verified_at')
            || !Schema::hasColumn('children', 'doc_verification_status')
            || !Schema::hasColumn('children', 'status')
            || !Schema::hasColumn('school_internal_identities', 'is_active')) {
            return response()->json(['error' => 'School student registration schema is unavailable'], 503);
        }
        $passwordColumn = Schema::hasColumn('users', 'password_hash')
            ? 'password_hash' : (Schema::hasColumn('users', 'password') ? 'password' : null);
        if (!$passwordColumn) {
            return response()->json(['error' => 'Password storage is unavailable'], 503);
        }

        try {
            return DB::transaction(function () use ($request, $input, $name, $passwordColumn) {
                // Only the uniquely appointed, active director can perform this action.
                $school = SchoolAdministration::directorSchool($request, true);
                if (!$school) return response()->json(['error' => 'School access is unavailable'], 403);

                // Institution schools have their own admissions approval workflow.
                // In particular, do not bypass Jabalia counselor/admin sign-off.
                if ($school->organization_id !== null) {
                    return response()->json(['error' => 'Use institution admissions for this school'], 403);
                }
                if (!$school->internal_domain || !$school->internal_domain_confirmed_at) {
                    return response()->json(['error' => 'Internal domain must be confirmed'], 409);
                }

                $section = DB::table('sections as section')
                    ->join('grades as grade', 'grade.id', '=', 'section.grade_id')
                    ->join('academic_years as year', 'year.id', '=', 'section.academic_year_id')
                    ->where('section.id', (int) $input['section_id'])
                    ->where('grade.school_id', $school->id)
                    ->where('year.school_id', $school->id)
                    ->where('grade.is_active', true)
                    ->where('year.is_current', true)
                    ->select('section.id', 'section.capacity')
                    ->lockForUpdate()->first();
                if (!$section) {
                    return response()->json(['error' => 'Current school section is unavailable'], 422);
                }
                if ($section->capacity !== null
                    && DB::table('student_enrollments')->where('section_id', $section->id)
                        ->where('status', 'active')->count() >= (int) $section->capacity) {
                    return response()->json(['error' => 'Section is full'], 409);
                }

                $email = $input['username'].'@'.$school->internal_domain;
                if (DB::table('users')->where('email', $email)->exists()
                    || DB::table('school_internal_identities')
                        ->where('school_id', $school->id)
                        ->where('username', $input['username'])->exists()) {
                    return response()->json(['error' => 'Internal username is already taken'], 409);
                }

                // A school-created child is not a document-verified child.
                // No guardian link, national ID, medical report or other evidence is fabricated.
                $child = ['name' => $name, 'status' => 'pending',
                    'doc_verification_status' => 'pending'];
                if (Schema::hasColumn('children', 'created_at')) $child['created_at'] = now();
                $childId = DB::table('children')->insertGetId($child);

                $enrollmentId = DB::table('student_enrollments')->insertGetId([
                    'child_id' => $childId, 'section_id' => $section->id,
                    'status' => 'active', 'enrolled_on' => now()->toDateString(),
                    'created_at' => now(), 'updated_at' => now(),
                ]);

                $hash = password_hash($input['password'], PASSWORD_BCRYPT);
                $user = ['name' => $name, 'email' => $email, 'role' => 'student',
                    $passwordColumn => $hash, 'email_verified_at' => now()];
                if (Schema::hasColumn('users', 'password')
                    && Schema::hasColumn('users', 'password_hash')) {
                    $user['password'] = $hash;
                    $user['password_hash'] = $hash;
                }
                // The school-issued internal login is trusted, not the child's documents.
                if (Schema::hasColumn('users', 'verification_status')) {
                    $user['verification_status'] = 'verified';
                }
                foreach (['created_at', 'updated_at'] as $column) {
                    if (Schema::hasColumn('users', $column)) $user[$column] = now();
                }
                $userId = DB::table('users')->insertGetId($user);

                DB::table('school_internal_identities')->insert([
                    'school_id' => $school->id, 'user_id' => $userId,
                    'username' => $input['username'], 'is_active' => true,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                DB::table('student_account_links')->insert([
                    'user_id' => $userId, 'child_id' => $childId,
                    'school_id' => $school->id,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                DB::table('school_administration_events')->insert([
                    'school_id' => $school->id,
                    'actor_id' => $request->attributes->get('jwt_user')->id,
                    'action' => 'direct_student_registration',
                    'subject_id' => $childId,
                    'created_at' => now(),
                ]);

                return response()->json([
                    'school_id' => (int) $school->id,
                    'child_id' => (int) $childId,
                    'enrollment_id' => (int) $enrollmentId,
                    'user_id' => (int) $userId,
                    'username' => $input['username'],
                    'login_identifier' => $email,
                    'role' => 'student',
                    'document_verification' => 'pending',
                ], 201);
            }, 3);
        } catch (QueryException $e) {
            if (in_array((string) ($e->errorInfo[0] ?? $e->getCode()), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Student registration conflicts with an existing record'], 409);
            }
            throw $e;
        }
    }
}
