<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolInternalAccountController;
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
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id'); $t->string('status');
        });
        Schema::create('student_account_links', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id')->unique(); $t->unsignedBigInteger('child_id')->unique();
            $t->unsignedBigInteger('school_id'); $t->timestamps();
        });
        DB::table('grades')->insert(['id'=>1,'school_id'=>10]);
        DB::table('sections')->insert(['id'=>1,'grade_id'=>1]);
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
        foreach (['student_account_links','student_enrollments','sections','grades'] as $table) Schema::dropIfExists($table);
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
}
