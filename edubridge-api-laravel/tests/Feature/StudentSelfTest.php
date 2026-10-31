<?php

namespace Tests\Feature;

use App\Http\Controllers\StudentSelfController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class StudentSelfTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->boolean('is_active'); });
        Schema::create('school_internal_identities', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->boolean('is_active');
        });
        Schema::create('student_account_links', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id'); $t->unsignedBigInteger('child_id');
            $t->unsignedBigInteger('school_id');
        });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id'); $t->string('status');
        });
        DB::table('schools')->insert([['id'=>1,'is_active'=>true],['id'=>2,'is_active'=>true]]);
        DB::table('school_internal_identities')->insert(['school_id'=>1,'user_id'=>10,'is_active'=>true]);
        DB::table('student_account_links')->insert(['school_id'=>1,'user_id'=>10,'child_id'=>100]);
        DB::table('children')->insert([['id'=>100,'name'=>'Student A'],['id'=>101,'name'=>'Student B']]);
        DB::table('grades')->insert([['id'=>1,'school_id'=>1],['id'=>2,'school_id'=>2]]);
        DB::table('sections')->insert([['id'=>1,'grade_id'=>1],['id'=>2,'grade_id'=>2]]);
        DB::table('student_enrollments')->insert([
            ['child_id'=>100,'section_id'=>1,'status'=>'active'],
            ['child_id'=>101,'section_id'=>2,'status'=>'active'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['student_enrollments','sections','grades','children','student_account_links',
            'school_internal_identities','schools'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function requestAs(int $id, string $role): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/student/me','GET');
        $request->attributes->set('jwt_user',(object)['id'=>$id,'role'=>$role]);
        return app(StudentSelfController::class)->show($request);
    }

    public function test_student_only_sees_linked_child(): void
    {
        $response = $this->requestAs(10, 'student');
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame(100, $response->getData(true)['student']['child_id']);
        $this->assertArrayNotHasKey('email', $response->getData(true)['student']);
        $this->assertSame(403, $this->requestAs(20, 'student')->getStatusCode());
        $this->assertSame(403, $this->requestAs(10, 'parent')->getStatusCode());
    }

    public function test_revocation_and_cross_school_enrollment_block_profile(): void
    {
        DB::table('school_internal_identities')->where('user_id',10)->update(['is_active'=>false]);
        $this->assertSame(403, $this->requestAs(10,'student')->getStatusCode());
        DB::table('school_internal_identities')->where('user_id',10)->update(['is_active'=>true]);
        DB::table('student_enrollments')->where('child_id',100)->update(['section_id'=>2]);
        $this->assertSame(403, $this->requestAs(10,'student')->getStatusCode());
    }
}
