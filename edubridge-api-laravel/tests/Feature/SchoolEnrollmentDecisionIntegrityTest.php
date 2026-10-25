<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolEnrollmentDecisionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolEnrollmentDecisionIntegrityTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', fn (Blueprint $t) => $this->idActive($t));
        Schema::create('schools', function (Blueprint $t) {
            $this->idActive($t); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable();
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->string('name');
        });
        Schema::create('grades', function (Blueprint $t) {
            $this->idActive($t); $t->unsignedBigInteger('school_id');
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->boolean('is_current');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id');
            $t->unsignedBigInteger('academic_year_id'); $t->unsignedInteger('capacity')->nullable();
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id');
            $t->string('status'); $t->date('enrolled_on')->nullable(); $t->timestamps();
        });
        Schema::create('school_enrollment_requests', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->unsignedInteger('version'); $t->text('reason')->nullable();
            $t->unsignedBigInteger('decided_by')->nullable(); $t->timestamp('decided_at')->nullable();
            $t->timestamps();
        });
        Schema::create('child_parent', function (Blueprint $t) {
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id');
        });
        Schema::create('notifications', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id'); $t->string('title');
            $t->text('message'); $t->string('type')->nullable();
        });
        DB::table('child_parent')->insert(['child_id'=>10,'parent_id'=>25]);
        DB::table('schools')->insert([
            ['id'=>1,'name'=>'Own','is_active'=>true,'organization_id'=>null],
            ['id'=>2,'name'=>'Other','is_active'=>true,'organization_id'=>null],
        ]);
        DB::table('school_accounts')->insert(['school_id'=>1,'user_id'=>7]);
        DB::table('children')->insert([['id'=>10,'name'=>'A'],['id'=>11,'name'=>'B']]);
        DB::table('grades')->insert([
            ['id'=>1,'school_id'=>1,'is_active'=>true],
            ['id'=>2,'school_id'=>2,'is_active'=>true],
        ]);
        DB::table('academic_years')->insert([
            ['id'=>1,'school_id'=>1,'is_current'=>true],
            ['id'=>2,'school_id'=>2,'is_current'=>true],
        ]);
        DB::table('sections')->insert([
            ['id'=>1,'grade_id'=>1,'academic_year_id'=>1,'capacity'=>1],
            ['id'=>2,'grade_id'=>2,'academic_year_id'=>2,'capacity'=>10],
        ]);
        DB::table('school_enrollment_requests')->insert([
            ['id'=>100,'school_id'=>1,'child_id'=>10,'status'=>'pending','version'=>1,'created_at'=>now(),'updated_at'=>now()],
            ['id'=>101,'school_id'=>2,'child_id'=>11,'status'=>'pending','version'=>1,'created_at'=>now(),'updated_at'=>now()],
        ]);
    }

    private function idActive(Blueprint $table): void
    {
        $table->id(); $table->boolean('is_active');
    }

    protected function tearDown(): void
    {
        foreach (['notifications','child_parent','school_enrollment_requests','student_enrollments','sections','academic_years',
            'grades','children','school_accounts','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function decide(int $requestId, array $body): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/enrollment-requests/'.$requestId.'/decision','POST',$body);
        $request->attributes->set('jwt_user',(object)['id'=>7,'role'=>'school']);
        return app(SchoolEnrollmentDecisionController::class)->decide($request,$requestId);
    }

    public function test_approval_creates_one_enrollment_without_recreating_child(): void
    {
        $body = ['decision'=>'approved','expected_version'=>1,'section_id'=>1];
        $result = $this->decide(100,$body);
        $this->assertSame(200,$result->getStatusCode());
        $this->assertSame(10,$result->getData(true)['enrollment']['child_id']);
        $this->assertSame(2,DB::table('children')->count());
        $this->assertSame(1,DB::table('student_enrollments')->count());
        $this->assertSame(2,DB::table('school_enrollment_requests')->where('id',100)->value('version'));
        $this->assertSame(409,$this->decide(100,$body)->getStatusCode());
        $this->assertSame(1,DB::table('student_enrollments')->count());
        $this->assertSame(1, DB::table('notifications')->where('user_id',25)
            ->where('type','school_enrollment')->count());
    }

    public function test_foreign_school_request_and_section_are_denied(): void
    {
        $this->assertSame(404,$this->decide(101,[
            'decision'=>'approved','expected_version'=>1,'section_id'=>1,
        ])->getStatusCode());
        $this->assertSame(422,$this->decide(100,[
            'decision'=>'approved','expected_version'=>1,'section_id'=>2,
        ])->getStatusCode());
        $this->assertSame(0,DB::table('student_enrollments')->count());
    }

    public function test_full_section_and_stale_version_are_rejected(): void
    {
        DB::table('student_enrollments')->insert([
            'child_id'=>11,'section_id'=>1,'status'=>'active',
            'created_at'=>now(),'updated_at'=>now(),
        ]);
        $this->assertSame(409,$this->decide(100,[
            'decision'=>'approved','expected_version'=>1,'section_id'=>1,
        ])->getStatusCode());
        $this->assertSame(409,$this->decide(100,[
            'decision'=>'rejected','expected_version'=>2,'reason'=>'Reason',
        ])->getStatusCode());
        $this->assertSame('pending',DB::table('school_enrollment_requests')->where('id',100)->value('status'));
        $this->assertSame(0,DB::table('notifications')->count());
    }

    public function test_rejection_does_not_enroll_child(): void
    {
        $result=$this->decide(100,[
            'decision'=>'rejected','expected_version'=>1,'reason'=>'Not available',
        ]);
        $this->assertSame(200,$result->getStatusCode());
        $this->assertNull($result->getData(true)['enrollment']);
        $this->assertSame(0,DB::table('student_enrollments')->count());
        $this->assertSame('rejected',DB::table('school_enrollment_requests')->where('id',100)->value('status'));
        $this->assertSame(1,DB::table('notifications')->where('user_id',25)->count());
    }
}
