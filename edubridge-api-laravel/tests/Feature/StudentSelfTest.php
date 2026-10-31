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
        Schema::create('subjects', function (Blueprint $t) { $t->id(); $t->string('name'); });
        Schema::create('users', function (Blueprint $t) { $t->id(); $t->string('name'); });
        Schema::create('timetable_entries', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('section_id');
            $t->unsignedBigInteger('subject_id'); $t->unsignedBigInteger('teacher_id')->nullable();
            $t->integer('weekday'); $t->integer('period_number');
            $t->time('starts_at')->nullable(); $t->time('ends_at')->nullable();
        });
        DB::table('subjects')->insert(['id'=>1,'name'=>'Math']);
        Schema::create('homeworks', function (Blueprint $t) {
            $t->id(); $t->string('title'); $t->text('description')->nullable();
            $t->date('due_date'); $t->text('assigned_child_ids');
        });
        DB::table('homeworks')->insert([
            ['title'=>'Mine','description'=>'Task A','due_date'=>'2026-11-01','assigned_child_ids'=>'[100]'],
            ['title'=>'Other','description'=>'Task B','due_date'=>'2026-11-02','assigned_child_ids'=>'[101]'],
        ]);
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
        foreach (['homeworks','timetable_entries','subjects','users','student_enrollments','sections','grades','children','student_account_links',
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

    public function test_student_timetable_cannot_include_other_school_or_section(): void
    {
        DB::table('timetable_entries')->insert([
            ['school_id'=>1,'section_id'=>1,'subject_id'=>1,'weekday'=>1,'period_number'=>1],
            ['school_id'=>2,'section_id'=>2,'subject_id'=>1,'weekday'=>1,'period_number'=>2],
        ]);
        $request = Request::create('/api/student/timetable','GET');
        $request->attributes->set('jwt_user',(object)['id'=>10,'role'=>'student']);
        $response = app(StudentSelfController::class)->timetable($request);
        $this->assertSame(200, $response->getStatusCode());
        $this->assertCount(1, $response->getData(true)['timetable']);
        $request->attributes->set('jwt_user',(object)['id'=>10,'role'=>'parent']);
        $this->assertSame(403, app(StudentSelfController::class)->timetable($request)->getStatusCode());
    }

    public function test_homeworks_are_limited_to_own_child(): void
    {
        $request = Request::create('/api/student/homeworks','GET');
        $request->attributes->set('jwt_user',(object)['id'=>10,'role'=>'student']);
        $response = app(StudentSelfController::class)->homeworks($request);
        $this->assertSame(200,$response->getStatusCode());
        $this->assertCount(1,$response->getData(true)['homeworks']);
        $this->assertSame('Mine',$response->getData(true)['homeworks'][0]['title']);
        $request->attributes->set('jwt_user',(object)['id'=>10,'role'=>'parent']);
        $this->assertSame(403,app(StudentSelfController::class)->homeworks($request)->getStatusCode());
    }

    public function test_parent_or_unlinked_student_cannot_submit_student_homework(): void
    {
        $request = Request::create('/api/student/homeworks/1/submit', 'POST', [
            'child_id' => 100, 'text_answer' => 'Attempted answer',
        ]);
        $request->attributes->set('jwt_user', (object) ['id'=>10, 'role'=>'parent']);
        $this->assertSame(403, app(\App\Http\Controllers\StudentHomeworkSubmitController::class)
            ->store($request, 1)->getStatusCode());

        $request->attributes->set('jwt_user', (object) ['id'=>20, 'role'=>'student']);
        $this->assertSame(403, app(\App\Http\Controllers\StudentHomeworkSubmitController::class)
            ->store($request, 1)->getStatusCode());
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
