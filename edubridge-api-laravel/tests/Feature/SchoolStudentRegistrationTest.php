<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolStudentRegistrationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolStudentRegistrationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active')->default(true);
            $t->string('internal_domain')->nullable(); $t->timestamp('internal_domain_confirmed_at')->nullable();
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('role'); $t->string('password_hash'); $t->string('password')->nullable();
            $t->timestamp('email_verified_at')->nullable(); $t->string('verification_status')->nullable();
            // Production users may have created_at but no updated_at.
            $t->timestamp('created_at')->nullable();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->boolean('is_current')->default(false);
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->boolean('is_active')->default(true);
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id');
            $t->unsignedInteger('capacity')->nullable();
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('status')->default('pending');
            $t->string('doc_verification_status')->default('pending'); $t->timestamp('created_at')->nullable();
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id');
            $t->string('status'); $t->date('enrolled_on')->nullable(); $t->timestamps();
        });
        Schema::create('school_internal_identities', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id')->unique();
            $t->string('username'); $t->boolean('is_active')->default(true); $t->timestamps();
            $t->unique(['school_id', 'username']);
        });
        Schema::create('student_account_links', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id')->unique();
            $t->unsignedBigInteger('child_id')->unique(); $t->timestamps();
        });
        Schema::create('school_administration_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('actor_id');
            $t->string('action'); $t->unsignedBigInteger('subject_id')->nullable(); $t->timestamp('created_at');
        });
        Schema::create('child_parent', function (Blueprint $t) {
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id');
        });

        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => null, 'is_active' => true, 'internal_domain' => 'independent.edubridge', 'internal_domain_confirmed_at' => now()],
            ['id' => 11, 'organization_id' => 1, 'is_active' => true, 'internal_domain' => 'institution.edubridge', 'internal_domain_confirmed_at' => now()],
            ['id' => 12, 'organization_id' => null, 'is_active' => true, 'internal_domain' => 'other.edubridge', 'internal_domain_confirmed_at' => now()],
        ]);
        DB::table('school_management_assignments')->insert([
            ['school_id' => 10, 'user_id' => 20, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 10, 'user_id' => 21, 'role' => 'deputy_director', 'ends_at' => null],
            ['school_id' => 11, 'user_id' => 22, 'role' => 'director', 'ends_at' => null],
        ]);
        DB::table('academic_years')->insert([
            ['id' => 1, 'school_id' => 10, 'is_current' => true],
            ['id' => 2, 'school_id' => 12, 'is_current' => true],
        ]);
        DB::table('grades')->insert([
            ['id' => 1, 'school_id' => 10, 'is_active' => true],
            ['id' => 2, 'school_id' => 12, 'is_active' => true],
        ]);
        DB::table('sections')->insert([
            ['id' => 1, 'grade_id' => 1, 'academic_year_id' => 1, 'capacity' => 2],
            ['id' => 2, 'grade_id' => 2, 'academic_year_id' => 2, 'capacity' => 2],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['child_parent', 'school_administration_events', 'student_account_links',
            'school_internal_identities', 'student_enrollments', 'children', 'sections',
            'grades', 'academic_years', 'school_management_assignments', 'users',
            'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function register(int $actor = 20, string $role = 'school_director', array $override = []): \Illuminate\Http\JsonResponse
    {
        $input = array_merge([
            'expected_school_id' => 10,
            'name' => 'QA Student',
            'username' => 'qa-student',
            'password' => 'StrongPassword123!',
            'section_id' => 1,
            'guardian_authorization_confirmed' => true,
        ], $override);
        $request = Request::create('/api/school/students', 'POST', $input);
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => $role]);
        return app(SchoolStudentRegistrationController::class)->store($request);
    }

    public function test_director_registers_complete_student_atomically_without_faking_guardian_documents(): void
    {
        $response = $this->register();
        $this->assertSame(201, $response->getStatusCode());
        $receipt = $response->getData(true);
        $this->assertSame('qa-student@independent.edubridge', $receipt['login_identifier']);
        $this->assertSame('pending', $receipt['document_verification']);
        $this->assertArrayNotHasKey('password', $receipt);
        $user = DB::table('users')->find($receipt['user_id']);
        $this->assertSame('student', $user->role);
        $this->assertTrue(password_verify('StrongPassword123!', $user->password_hash));
        $this->assertSame($user->password_hash, $user->password);
        $this->assertNotNull($user->email_verified_at);
        $this->assertSame('verified', $user->verification_status);
        $child = DB::table('children')->find($receipt['child_id']);
        $this->assertSame('pending', $child->doc_verification_status);
        $this->assertSame('pending', $child->status);
        $this->assertSame(0, DB::table('child_parent')->count());
        $this->assertSame(1, DB::table('student_enrollments')
            ->where('child_id', $child->id)->where('section_id', 1)->where('status', 'active')->count());
        $this->assertSame(1, DB::table('student_account_links')
            ->where('school_id', 10)->where('child_id', $child->id)->where('user_id', $user->id)->count());
        $this->assertSame(1, DB::table('school_administration_events')
            ->where('school_id', 10)->where('actor_id', 20)->where('subject_id', $child->id)
            ->where('action', 'direct_student_registration')->count());
    }

    public function test_direct_registration_requires_unique_active_director_and_correct_school(): void
    {
        $this->assertSame(403, $this->register(21)->getStatusCode());
        $this->assertSame(403, $this->register(99)->getStatusCode());
        $this->assertSame(403, $this->register(22, 'school_director', ['expected_school_id' => 11])->getStatusCode());
        $this->assertSame(403, $this->register(20, 'school', ['expected_school_id' => 10])->getStatusCode());
        $this->assertSame(403, $this->register(20, 'school_director', ['expected_school_id' => 12])->getStatusCode());
        $this->assertSame(0, DB::table('users')->count());
        $this->assertSame(0, DB::table('children')->count());
    }

    public function test_foreign_or_noncurrent_sections_and_missing_authorization_are_rejected_without_writes(): void
    {
        $this->assertSame(422, $this->register(20, 'school_director', ['section_id' => 2])->getStatusCode());
        DB::table('academic_years')->where('id', 1)->update(['is_current' => false]);
        $this->assertSame(422, $this->register()->getStatusCode());
        DB::table('academic_years')->where('id', 1)->update(['is_current' => true]);
        $this->assertSame(422, $this->register(20, 'school_director', ['guardian_authorization_confirmed' => false])->getStatusCode());
        $this->assertSame(422, $this->register(20, 'school_director', ['doc_verification_status' => 'verified'])->getStatusCode());
        $this->assertSame(422, $this->register(20, 'school_director', ['parent_id' => 999])->getStatusCode());
        $this->assertSame(0, DB::table('children')->count());
        $this->assertSame(0, DB::table('users')->count());
    }

    public function test_duplicate_username_and_full_section_do_not_leave_partial_student_records(): void
    {
        $this->assertSame(201, $this->register()->getStatusCode());
        $this->assertSame(409, $this->register()->getStatusCode());
        $this->assertSame(201, $this->register(20, 'school_director', ['username' => 'qa-student-2'])->getStatusCode());
        $this->assertSame(409, $this->register(20, 'school_director', ['username' => 'qa-student-3'])->getStatusCode());
        $this->assertSame(2, DB::table('users')->count());
        $this->assertSame(2, DB::table('children')->count());
        $this->assertSame(2, DB::table('student_account_links')->count());
    }

    public function test_inactive_school_and_revoked_director_are_denied(): void
    {
        DB::table('school_management_assignments')->where('user_id', 20)->update(['ends_at' => now()]);
        $this->assertSame(403, $this->register()->getStatusCode());
        DB::table('school_management_assignments')->where('user_id', 20)->update(['ends_at' => null]);
        DB::table('schools')->where('id', 10)->update(['is_active' => false]);
        $this->assertSame(403, $this->register()->getStatusCode());
        $this->assertSame(0, DB::table('children')->count());
    }
}
