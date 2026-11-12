<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolInternalAccountController;
use App\Http\Controllers\SchoolInternalDomainController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolInternalAccountTest extends TestCase
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
            $t->string('internal_domain')->nullable()->unique();
            $t->timestamp('internal_domain_confirmed_at')->nullable();
            $t->timestamps();
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
            $t->timestamps();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
            $t->string('role');
            $t->timestamp('ends_at')->nullable();
        });
        Schema::create('school_internal_identities', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id')->unique();
            $t->string('username');
            $t->timestamps();
            $t->unique(['school_id', 'username']);
        });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); $t->date('birth_date')->nullable(); $t->unsignedBigInteger('organization_id')->nullable(); $t->string('status')->nullable(); $t->string('doc_verification_status')->nullable(); $t->string('guardian_national_id')->nullable(); });
        Schema::create('academic_years', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->boolean('is_current'); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->boolean('is_active')->default(true); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id'); $t->unsignedInteger('capacity')->nullable(); });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id'); $t->string('status'); $t->date('enrolled_on')->nullable(); $t->timestamps();
        });
        Schema::create('student_account_links', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id')->unique(); $t->unsignedBigInteger('child_id')->unique();
            $t->unsignedBigInteger('school_id'); $t->timestamps();
        });
        DB::table('academic_years')->insert(['id'=>1,'school_id'=>10,'is_current'=>true]);
        DB::table('grades')->insert(['id'=>1,'school_id'=>10,'is_active'=>true]);
        DB::table('sections')->insert(['id'=>1,'grade_id'=>1,'academic_year_id'=>1,'capacity'=>5]);
        DB::table('student_enrollments')->insert(['child_id'=>100,'section_id'=>1,'status'=>'active']);
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => 1, 'is_active' => true,
                'internal_domain' => 'alpha.edubridge', 'internal_domain_confirmed_at' => now()],
            ['id' => 11, 'organization_id' => null, 'is_active' => true,
                'internal_domain' => 'beta.edubridge', 'internal_domain_confirmed_at' => now()],
        ]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 10, 'user_id' => 20, 'role' => 'director', 'ends_at' => null,
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['student_account_links','student_enrollments','sections','grades','academic_years','children'] as $table) Schema::dropIfExists($table);
        Schema::dropIfExists('school_internal_identities');
        Schema::dropIfExists('school_management_assignments');
        Schema::dropIfExists('users');
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    private function createAccount(int $actor = 20, array $override = []): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/internal-identities', 'POST', array_merge([
            'name' => 'Test Teacher', 'username' => 'teacher01',
            'role' => 'teacher', 'password' => 'StrongPassword123!',
        ], $override));
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => 'teacher']);
        return app(SchoolInternalAccountController::class)->store($request);
    }

    public function test_director_creates_scoped_teacher_and_student_with_hashed_passwords(): void
    {
        $response = $this->createAccount();
        $this->assertSame(201, $response->getStatusCode());
        $data = $response->getData(true);
        $this->assertSame('teacher01@alpha.edubridge', $data['login_identifier']);
        $this->assertArrayNotHasKey('password', $data);
        $user = DB::table('users')->where('id', $data['user_id'])->first();
        $this->assertTrue(password_verify('StrongPassword123!', $user->password_hash));
        $this->assertSame($user->password_hash, $user->password);
        $this->assertNotNull($user->email_verified_at);
        $this->assertSame(10, DB::table('school_internal_identities')
            ->where('user_id', $user->id)->value('school_id'));
        $this->assertSame(201, $this->createAccount(20, [
            'username' => 'student01', 'role' => 'student', 'child_id' => 100,
        ])->getStatusCode());
        $this->assertSame(2, DB::table('school_internal_identities')->count());
        $this->assertSame(100, (int) DB::table('student_account_links')->value('child_id'));
        $this->assertSame(409, $this->createAccount(20, ['username'=>'student02','role'=>'student','child_id'=>100])->getStatusCode());
        $this->assertSame(422, $this->createAccount(20, ['username'=>'student03','role'=>'student','child_id'=>101])->getStatusCode());
    }

    public function test_direct_school_student_registration_creates_pending_child_and_active_enrollment_atomically(): void
    {
        $response = $this->createAccount(20, [
            'name' => 'QA Student', 'username' => 'qa-student', 'role' => 'student',
            'create_student' => true, 'section_id' => 1, 'birth_date' => '2018-05-15',
        ]);

        $this->assertSame(201, $response->getStatusCode());
        $data = $response->getData(true);
        $this->assertSame('qa-student@alpha.edubridge', $data['login_identifier']);
        $this->assertSame('student', $data['role']);
        $this->assertGreaterThan(0, $data['child_id']);
        $child = DB::table('children')->find($data['child_id']);
        $this->assertSame('pending', $child->status);
        $this->assertSame('pending', $child->doc_verification_status);
        $this->assertNull($child->organization_id);
        $this->assertSame('2018-05-15', $child->birth_date);
        $this->assertSame(1, DB::table('student_enrollments')
            ->where('child_id', $child->id)->where('section_id', 1)->where('status', 'active')->count());
        $this->assertSame((int) $child->id, (int) DB::table('student_account_links')
            ->where('user_id', $data['user_id'])->value('child_id'));
        $this->assertNull(DB::table('children')->where('id', $child->id)->value('guardian_national_id'));
    }

    public function test_direct_registration_rejects_foreign_school_section_and_institution_school(): void
    {
        DB::table('academic_years')->insert(['id'=>2,'school_id'=>11,'is_current'=>true]);
        DB::table('grades')->insert(['id'=>2,'school_id'=>11,'is_active'=>true]);
        DB::table('sections')->insert(['id'=>2,'grade_id'=>2,'academic_year_id'=>2,'capacity'=>2]);

        $input = ['role'=>'student', 'username'=>'bad-student', 'create_student'=>true,
            'birth_date'=>'2017-02-02', 'section_id'=>2];
        $this->assertSame(422, $this->createAccount(20, $input)->getStatusCode());
        $input['section_id'] = 1;
        DB::table('schools')->where('id', 10)->update(['organization_id'=>1]);
        $this->assertSame(403, $this->createAccount(20, $input)->getStatusCode());
        $this->assertSame(0, DB::table('children')->count());
        $this->assertSame(0, DB::table('users')->count());
    }

    public function test_direct_student_creation_prevents_duplicates_and_full_sections(): void
    {
        $payload = ['name'=>'QA Student', 'username'=>'student-a', 'role'=>'student',
            'create_student'=>true, 'section_id'=>1, 'birth_date'=>'2017-01-20'];
        $this->assertSame(201, $this->createAccount(20, $payload)->getStatusCode());
        $this->assertSame(409, $this->createAccount(20,
            [...$payload, 'username'=>'student-b'])->getStatusCode());
        DB::table('sections')->where('id', 1)->update(['capacity'=>1]);
        $this->assertSame(409, $this->createAccount(20,
            [...$payload, 'name'=>'Different student', 'username'=>'student-c'])->getStatusCode());
        $this->assertSame(1, DB::table('children')->count());
        $this->assertSame(1, DB::table('users')->count());
        $this->assertSame(1, DB::table('student_enrollments')->where('status','active')->count());
    }

    public function test_direct_student_creation_requires_data_and_director(): void
    {
        $payload = ['role'=>'student','username'=>'student-a','create_student'=>true,
            'section_id'=>1,'birth_date'=>'2017-01-20'];
        $this->assertSame(422, $this->createAccount(20,
            [...$payload, 'birth_date'=>null])->getStatusCode());
        $this->assertSame(403, $this->createAccount(21, $payload)->getStatusCode());
        $this->assertSame(422, $this->createAccount(20,
            [...$payload, 'child_id'=>100])->getStatusCode());
        $this->assertSame(422, $this->createAccount(20,
            ['role'=>'staff', 'username'=>'invalid', 'create_student'=>true, 'section_id'=>1])->getStatusCode());
        $this->assertSame(0, DB::table('children')->count());
    }

    public function test_staff_account_creation_supports_users_without_updated_at(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('updated_at');
        });

        $response = $this->createAccount(20, [
            'name' => 'QA Staff', 'username' => 'qa-staff', 'role' => 'staff',
        ]);

        $this->assertSame(201, $response->getStatusCode());
        $data = $response->getData(true);
        $this->assertSame('qa-staff@alpha.edubridge', $data['login_identifier']);
        $this->assertSame('staff', $data['role']);

        $user = DB::table('users')->where('id', $data['user_id'])->first();
        $this->assertNotNull($user);
        $this->assertNotNull($user->created_at);
        $this->assertTrue(password_verify('StrongPassword123!', $user->password_hash));
        $this->assertSame('verified', $user->verification_status);
        $this->assertSame(10, (int) DB::table('school_internal_identities')
            ->where('user_id', $user->id)->value('school_id'));
    }

    public function test_staff_account_creation_supports_users_without_any_timestamps(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['created_at', 'updated_at']);
        });

        $response = $this->createAccount(20, [
            'name' => 'QA Staff', 'username' => 'qa-staff', 'role' => 'staff',
        ]);

        $this->assertSame(201, $response->getStatusCode());
        $data = $response->getData(true);
        $this->assertSame('qa-staff@alpha.edubridge', $data['login_identifier']);
        $this->assertSame('staff', DB::table('users')->where('id', $data['user_id'])->value('role'));
        $this->assertSame(10, (int) DB::table('school_internal_identities')
            ->where('user_id', $data['user_id'])->value('school_id'));
    }

    public function test_duplicate_username_and_invalid_input_are_rejected(): void
    {
        $this->assertSame(201, $this->createAccount()->getStatusCode());
        $this->assertSame(409, $this->createAccount()->getStatusCode());
        $this->assertSame(422, $this->createAccount(20, ['role' => 'admin'])->getStatusCode());
        $this->assertSame(422, $this->createAccount(20, ['password' => 'short'])->getStatusCode());
        $this->assertSame(422, $this->createAccount(20, ['username' => 'BAD USER'])->getStatusCode());
        $this->assertSame(1, DB::table('users')->count());
    }

    public function test_only_unique_active_director_with_confirmed_domain_can_create(): void
    {
        $this->assertSame(403, $this->createAccount(21)->getStatusCode());
        DB::table('schools')->where('id', 10)->update(['internal_domain_confirmed_at' => null]);
        $this->assertSame(409, $this->createAccount()->getStatusCode());
        DB::table('schools')->where('id', 10)->update(['internal_domain_confirmed_at' => now()]);
        DB::table('organizations')->where('id', 1)->update(['is_active' => false]);
        $this->assertSame(403, $this->createAccount()->getStatusCode());
        DB::table('organizations')->where('id', 1)->update(['is_active' => true]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 11, 'user_id' => 20, 'role' => 'director', 'ends_at' => null,
        ]);
        $this->assertSame(403, $this->createAccount()->getStatusCode());
        $this->assertSame(0, DB::table('users')->count());
    }
    private function confirmNamespace(string $value, int $actor = 20, string $role = 'school_director'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/internal-domain/confirm', 'POST', [
            'internal_domain' => $value, 'expected_school_id' => 10,
        ]);
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => $role]);
        return app(SchoolInternalDomainController::class)->confirm($request);
    }

    public function test_namespace_prefix_is_canonical_and_used_for_account_login_only(): void
    {
        DB::table('schools')->where('id', 10)->update([
            'internal_domain' => null, 'internal_domain_confirmed_at' => null,
        ]);
        $response = $this->confirmNamespace('alreyada');
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame('alreyada.edubridge', $response->getData(true)['internal_domain']);
        $this->assertSame('alreyada.edubridge', DB::table('schools')->where('id', 10)->value('internal_domain'));
        $this->assertSame('teacher01@alreyada.edubridge', $this->createAccount()->getData(true)['login_identifier']);
        $this->assertSame(409, $this->confirmNamespace('changed')->getStatusCode());
        $this->assertSame('alreyada.edubridge', DB::table('schools')->where('id', 10)->value('internal_domain'));
    }

    public function test_namespace_rejects_duplicate_or_invalid_and_school_account_cannot_confirm(): void
    {
        DB::table('schools')->where('id', 10)->update([
            'internal_domain' => null, 'internal_domain_confirmed_at' => null,
        ]);
        $this->assertSame(422, $this->confirmNamespace('bad.example.com')->getStatusCode());
        $this->assertSame(422, $this->confirmNamespace('ab')->getStatusCode());
        $this->assertSame(403, $this->confirmNamespace('other', 20, 'school')->getStatusCode());
        $this->assertSame(409, $this->confirmNamespace('beta')->getStatusCode());
        $this->assertNull(DB::table('schools')->where('id', 10)->value('internal_domain'));
        $this->assertSame(200, $this->confirmNamespace('alpha.edubridge')->getStatusCode());
        $this->assertSame('alpha.edubridge', DB::table('schools')->where('id', 10)->value('internal_domain'));
    }

}
