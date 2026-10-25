<?php

namespace Tests\Feature;

use App\Http\Controllers\GuardianSchoolRequestController;
use App\Http\Controllers\GuardianEnrollmentCancellationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class GuardianEnrollmentIntegrityTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->boolean('is_active');
            $t->unsignedBigInteger('organization_id')->nullable();
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->string('name');
        });
        Schema::create('child_parent', function (Blueprint $t) {
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id');
        });
        Schema::create('school_enrollment_requests', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('requested_by'); $t->string('status'); $t->unsignedInteger('version');
            $t->text('reason')->nullable(); $t->timestamps();
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->string('status');
        });
        DB::table('schools')->insert([
            ['id'=>10, 'name'=>'Our School', 'is_active'=>true, 'organization_id'=>null],
            ['id'=>11, 'name'=>'Other School', 'is_active'=>true, 'organization_id'=>null],
        ]);
        DB::table('children')->insert([['id'=>4,'name'=>'Child'],['id'=>5,'name'=>'Other Child']]);
        DB::table('child_parent')->insert(['child_id'=>4,'parent_id'=>2]);
    }

    protected function tearDown(): void
    {
        foreach (['student_enrollments','school_enrollment_requests','child_parent',
            'children','schools','organizations'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function submit(int $child = 4): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/parent/children/'.$child.'/enrollment-requests',
            'POST',['school_id'=>10]);
        $request->attributes->set('jwt_user',(object)['id'=>2,'role'=>'parent']);
        return app(GuardianSchoolRequestController::class)->submit($request,$child);
    }

    private function cancel(int $id, int $version): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/parent/children/4/enrollment-requests/'.$id.'/cancel',
            'POST',['expected_version'=>$version]);
        $request->attributes->set('jwt_user',(object)['id'=>2,'role'=>'parent']);
        return app(GuardianEnrollmentCancellationController::class)->cancel($request,4,$id);
    }

    public function test_guardian_can_submit_then_cancel_once(): void
    {
        $created = $this->submit();
        $this->assertSame(201,$created->getStatusCode());
        $id = $created->getData(true)['request']['id'];
        $this->assertSame(409,$this->submit()->getStatusCode());
        $this->assertSame(200,$this->cancel($id,1)->getStatusCode());
        $this->assertSame(409,$this->cancel($id,1)->getStatusCode());
        $this->assertSame('cancelled',DB::table('school_enrollment_requests')->where('id',$id)->value('status'));
        $this->assertSame(2,(int) DB::table('school_enrollment_requests')->where('id',$id)->value('version'));
        $this->assertSame(2,DB::table('children')->count());
    }

    public function test_guardian_cannot_submit_for_unrelated_child(): void
    {
        $this->assertSame(404,$this->submit(5)->getStatusCode());
        $this->assertSame(0,DB::table('school_enrollment_requests')->count());
    }

    public function test_active_enrollment_blocks_new_request(): void
    {
        DB::table('student_enrollments')->insert(['child_id'=>4,'status'=>'active']);
        $this->assertSame(409,$this->submit()->getStatusCode());
        $this->assertSame(0,DB::table('school_enrollment_requests')->count());
    }
}
