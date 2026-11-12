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
            'child_id' => ['nullable', 'integer', 'min:1'],
            'create_student' => ['sometimes', 'boolean'],
            'section_id' => ['required_if:create_student,true', 'nullable', 'integer', 'min:1'],
            'birth_date' => ['required_if:create_student,true', 'nullable', 'date', 'before:today', 'after:1900-01-01'],
            'password' => ['required', 'string', 'min:12', 'max:128'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }

        $input = $validation->validated();
        $directStudent = ($input['role'] === 'student' && ($input['create_student'] ?? false));
        if (($input['create_student'] ?? false) && $input['role'] !== 'student') {
            return response()->json(['error' => 'Direct provisioning is only available for students'], 422);
        }
        if ($directStudent && mb_strlen(trim($input['name'])) > 100) {
            return response()->json(['error' => 'Student name must not exceed 100 characters'], 422);
        }
        if ($directStudent && !empty($input['child_id'])) {
            return response()->json(['error' => 'Choose either an existing child or direct student creation'], 422);
        }
        if ($directStudent && (empty($input['section_id']) || empty($input['birth_date']))) {
            return response()->json(['error' => 'Student birth date and section are required'], 422);
        }
        if ($input['role'] === 'student' && !$directStudent && empty($input['child_id'])) {
            return response()->json(['error' => 'An enrolled child is required'], 422);
        }
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
            return DB::transaction(function () use ($request, $actor, $input, $passwordColumn, $directStudent) {
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

                $childId = $input['child_id'] ?? null;
                if ($input['role'] === 'student') {
                    if (!Schema::hasTable('student_account_links')) {
                        return response()->json(['error' => 'Student account linking is unavailable'], 503);
                    }
                    if ($directStudent) {
                        // Direct admissions must not bypass an institution's approval workflow.
                        if ($school->organization_id !== null) {
                            return response()->json(['error' => 'Direct admission is unavailable for institution schools'], 403);
                        }
                        if (!Schema::hasTable('children') || !Schema::hasTable('student_enrollments')) {
                            return response()->json(['error' => 'Student enrollment schema unavailable'], 503);
                        }
                        $section = DB::table('sections as s')
                            ->join('grades as g', 'g.id', '=', 's.grade_id')
                            ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
                            ->where('s.id', $input['section_id'])
                            ->where('g.school_id', $school->id)->where('g.is_active', true)
                            ->where('y.school_id', $school->id)->where('y.is_current', true)
                            ->select('s.id', 's.capacity')->lockForUpdate()->first();
                        if (!$section) return response()->json(['error' => 'Current school section unavailable'], 422);
                        if ($section->capacity !== null && DB::table('student_enrollments')
                            ->where('section_id', $section->id)->where('status', 'active')->count() >= (int) $section->capacity) {
                            return response()->json(['error' => 'Section is full'], 409);
                        }
                        // Reject likely duplicates in this school without exposing another child's data.
                        $duplicate = DB::table('children as c')
                            ->join('student_enrollments as e', 'e.child_id', '=', 'c.id')
                            ->join('sections as s', 's.id', '=', 'e.section_id')
                            ->join('grades as g', 'g.id', '=', 's.grade_id')
                            ->where('g.school_id', $school->id)->where('e.status', 'active')
                            ->where('c.name', trim($input['name']))
                            ->where('c.birth_date', $input['birth_date'])->exists();
                        if ($duplicate) return response()->json(['error' => 'Possible duplicate student in this school'], 409);
                    } else {
                    // An existing student login must belong to an enrolled child in this school.
                    $enrolled = DB::table('student_enrollments as e')
                        ->join('sections as s', 's.id', '=', 'e.section_id')
                        ->join('grades as g', 'g.id', '=', 's.grade_id')
                        ->where('e.child_id', $childId)
                        ->where('g.school_id', $school->id)
                        ->where('e.status', 'active')->exists();
                    if (!$enrolled) {
                        return response()->json(['error' => 'Student is not actively enrolled at this school'], 422);
                    }
                    if (DB::table('student_account_links')->where('child_id', $childId)->exists()) {
                        return response()->json(['error' => 'This student already has a login account'], 409);
                    }
                    }
                }

                $email = $input['username'].'@'.$school->internal_domain;
                if (DB::table('users')->where('email', $email)->exists()
                    || DB::table('school_internal_identities')
                        ->where('school_id', $school->id)->where('username', $input['username'])->exists()) {
                    return response()->json(['error' => 'Internal username is already taken'], 409);
                }

                if ($directStudent) {
                    // A school-managed academic record is not a verified identity or guardian relationship.
                    $childId = DB::table('children')->insertGetId([
                        'name' => trim($input['name']), 'birth_date' => $input['birth_date'],
                        'organization_id' => null, 'status' => 'pending',
                        'doc_verification_status' => 'pending',
                    ]);
                    DB::table('student_enrollments')->insert([
                        'child_id' => $childId, 'section_id' => $section->id,
                        'status' => 'active', 'enrolled_on' => now()->toDateString(),
                        'created_at' => now(), 'updated_at' => now(),
                    ]);
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
                }
                if (Schema::hasColumn('users', 'updated_at')) {
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
                        'child_id' => $childId,
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
                    'child_id' => $input['role'] === 'student' ? (int) $childId : null,
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
