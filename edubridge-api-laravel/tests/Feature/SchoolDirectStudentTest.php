<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolDirectStudentController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolDirectStudentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('organizations', function (Blueprint $t) {
            $t->id();
            $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active')->default(true);
            $t->string('internal_domain')->nullable();
            $t->timestamp('internal_domain_confirmed_at')->nullable();
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email')->unique();
            $t->string('role');
            $t->string('password_hash');
            $t->string('password')->nullable();
            $t->timestamp('email_verified_at')->nullable();
            $t->string('verification_status')->nullable();
            $t->timestamp('created_at')->nullable();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
            $t->string('role');
            $t->timestamp('ends_at')->nullable();
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->boolean('is_current');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->boolean('is_active');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('grade_id');
            $t->unsignedBigInteger('academic_year_id');
            $t->unsignedInteger('capacity')->nullable();
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id();
            $t->string('name', 100);
            $t->unsignedBigInteger('organization_id')->nullable();
            $t->string('status')->default('pending');
            $t->string('doc_verification_status')->default('pending');
            $t->string('child_national_id')->nullable();
            $t->string('guardian_national_id')->nullable();
            $t->timestamp('created_at')->nullable();
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('child_id');
            $t->unsignedBigInteger('section_id');
            $t->string('status');
            $t->date('enrolled_on')->nullable();
            $t->timestamps();
        });
        Schema::create('school_internal_identities', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id')->unique();
            $t->string('username');
            $t->boolean('is_active')->default(true);
            $t->timestamps();
            $t->unique(['school_id', 'username']);
        });
        Schema::create('student_account_links', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('user_id')->unique();
            $t->unsignedBigInteger('child_id')->unique();
            $t->unsignedBigInteger('school_id');
            $t->timestamps();
        });
        Schema::create('school_direct_student_admissions', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('child_id')->unique();
            $t->string('student_number');
            $t->unsignedBigInteger('created_by');
            $t->timestamps();
            $t->unique(['school_id', 'student_number']);
        });
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => null, 'is_active' => true,
                'internal_domain' => 'qa.edubridge', 'internal_domain_confirmed_at' => now()],
            ['id' => 11, 'organization_id' => null, 'is_active' => true,
                'internal_domain' => 'other.edubridge', 'internal_domain_confirmed_at' => now()],
            ['id' => 12, 'organization_id' => 1, 'is_active' => true,
                'internal_domain' => 'institution.edubridge', 'internal_domain_confirmed_at' => now()],
        ]);
        DB::table('school_management_assignments')->insert([
            ['school_id' => 10, 'user_id' => 20, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 11, 'user_id' => 21, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 12, 'user_id' => 22, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 10, 'user_id' => 23, 'role' => 'deputy_director', 'ends_at' => null],
        ]);
        DB::table('academic_years')->insert([
            ['id' => 100, 'school_id' => 10, 'is_current' => true],
            ['id' => 101, 'school_id' => 10, 'is_current' => false],
            ['id' => 110, 'school_id' => 11, 'is_current' => true],
            ['id' => 120, 'school_id' => 12, 'is_current' => true],
        ]);
        DB::table('grades')->insert([
            ['id' => 100, 'school_id' => 10, 'is_active' => true],
            ['id' => 101, 'school_id' => 10, 'is_active' => false],
            ['id' => 110, 'school_id' => 11, 'is_active' => true],
            ['id' => 120, 'school_id' => 12, 'is_active' => true],
        ]);
        DB::table('sections')->insert([
            ['id' => 100, 'grade_id' => 100, 'academic_year_id' => 100, 'capacity' => 1],
            ['id' => 101, 'grade_id' => 101, 'academic_year_id' => 100, 'capacity' => 10],
            ['id' => 102, 'grade_id' => 100, 'academic_year_id' => 101, 'capacity' => 10],
            ['id' => 110, 'grade_id' => 110, 'academic_year_id' => 110, 'capacity' => 10],
            ['id' => 120, 'grade_id' => 120, 'academic_year_id' => 120, 'capacity' => 10],
        ]);
    }

    protected function tearDown(): void
    {
        foreach ([
            'school_direct_student_admissions', 'student_account_links',
            'school_internal_identities', 'student_enrollments',
            'children', 'sections', 'grades', 'academic_years',
            'school_management_assignments', 'users', 'schools', 'organizations',
        ] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function submit(array $overrides = [], int $actor = 20, string $role = 'school_director'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/students/direct', 'POST', array_merge([
            'expected_school_id' => 10,
            'name' => 'QA Student',
            'username' => 'student01',
            'student_number' => 'QA-0001',
            'section_id' => 100,
            'password' => 'StrongPassword123!',
            'school_authorized' => true,
        ], $overrides));
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => $role]);
        return app(SchoolDirectStudentController::class)->store($request);
    }

    public function test_director_creates_student_with_pending_child_verification_and_no_parent(): void
    {
        $response = $this->submit();
        $this->assertSame(201, $response->getStatusCode());
        $body = $response->getData(true);
        $this->assertSame('student01@qa.edubridge', $body['login_identifier']);
        $this->assertSame('QA-0001', $body['student_number']);
        $this->assertArrayNotHasKey('password', $body);
        $this->assertArrayNotHasKey('password_hash', $body);
        $this->assertSame('student', DB::table('users')->where('id', $body['user_id'])->value('role'));
        $user = DB::table('users')->where('id', $body['user_id'])->first();
        $this->assertTrue(password_verify('StrongPassword123!', $user->password_hash));
        $this->assertNotNull($user->email_verified_at);

        $child = DB::table('children')->where('id', $body['child_id'])->first();
        $this->assertSame('pending', $child->doc_verification_status);
        $this->assertNull($child->guardian_national_id);
        $this->assertNull($child->child_national_id);
        $this->assertNull($child->organization_id);
        $this->assertSame(100, (int) DB::table('student_enrollments')->value('section_id'));
        $this->assertSame('active', DB::table('student_enrollments')->value('status'));
        $this->assertSame(10, (int) DB::table('student_account_links')->value('school_id'));
        $this->assertSame(20, (int) DB::table('school_direct_student_admissions')->value('created_by'));
    }

    public function test_duplicate_student_number_username_and_capacity_fail_without_partial_records(): void
    {
        $this->assertSame(201, $this->submit()->getStatusCode());
        $this->assertSame(409, $this->submit(['username'=>'student02','student_number'=>'qa-0001'])->getStatusCode());
        $this->assertSame(409, $this->submit(['student_number'=>'QA-0002'])->getStatusCode());
        $this->assertSame(409, $this->submit(['username'=>'student03','student_number'=>'QA-0003'])->getStatusCode());
        $this->assertSame(1, DB::table('children')->count());
        $this->assertSame(1, DB::table('student_enrollments')->count());
        $this->assertSame(1, DB::table('users')->count());
        $this->assertSame(1, DB::table('student_account_links')->count());
    }

    public function test_cannot_create_for_other_school_or_non_current_or_inactive_section(): void
    {
        foreach ([101,102,110] as $section) {
            $this->assertSame(422, $this->submit(['section_id'=>$section])->getStatusCode());
        }
        $this->assertSame(403, $this->submit(['expected_school_id'=>11])->getStatusCode());
        $this->assertSame(0, DB::table('children')->count());
    }

    public function test_denies_unapproved_authorization_and_non_directors_and_institution_schools(): void
    {
        $this->assertSame(422, $this->submit(['school_authorized'=>false])->getStatusCode());
        $this->assertSame(422, $this->submit(['parent_id'=>44])->getStatusCode());
        $this->assertSame(403, $this->submit([], 20, 'school')->getStatusCode());
        $this->assertSame(403, $this->submit([], 23)->getStatusCode());
        $this->assertSame(403, $this->submit([], 99)->getStatusCode());
        $this->assertSame(403, $this->submit(['expected_school_id'=>12,'section_id'=>120],22)->getStatusCode());
        $this->assertSame(0, DB::table('children')->count());
    }

    public function test_revoked_director_or_unconfirmed_domain_cannot_create(): void
    {
        DB::table('school_management_assignments')->where('user_id',20)->update(['ends_at'=>now()]);
        $this->assertSame(403, $this->submit()->getStatusCode());
        DB::table('school_management_assignments')->where('user_id',20)->update(['ends_at'=>null]);
        DB::table('schools')->where('id',10)->update(['internal_domain_confirmed_at'=>null]);
        $this->assertSame(409, $this->submit()->getStatusCode());
        $this->assertSame(0, DB::table('children')->count());
    }
}
