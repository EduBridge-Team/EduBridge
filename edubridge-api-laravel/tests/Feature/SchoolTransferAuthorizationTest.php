<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolTransferConsentController;
use App\Http\Controllers\SchoolTransferDestinationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolTransferAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', fn (Blueprint $t) => [$t->id(), $t->boolean('is_active')->default(true)]);
        Schema::create('schools', fn (Blueprint $t) => [$t->id(), $t->unsignedBigInteger('organization_id')->nullable(), $t->boolean('is_active')->default(true)]);
        Schema::create('children', fn (Blueprint $t) => [$t->id()]);
        Schema::create('child_parent', fn (Blueprint $t) => [$t->unsignedBigInteger('child_id'), $t->unsignedBigInteger('parent_id')]);
        Schema::create('grades', fn (Blueprint $t) => [$t->id(), $t->unsignedBigInteger('school_id')]);
        Schema::create('sections', fn (Blueprint $t) => [$t->id(), $t->unsignedBigInteger('grade_id'), $t->unsignedBigInteger('academic_year_id'), $t->unsignedInteger('capacity')->nullable()]);
        Schema::create('student_enrollments', fn (Blueprint $t) => [$t->id(), $t->unsignedBigInteger('child_id'), $t->unsignedBigInteger('section_id'), $t->string('status'), $t->date('enrolled_on'), $t->date('left_on')->nullable(), $t->timestamps()]);
        Schema::create('school_management_assignments', fn (Blueprint $t) => [$t->id(), $t->unsignedBigInteger('school_id'), $t->unsignedBigInteger('user_id'), $t->string('role'), $t->timestamp('ends_at')->nullable()]);
        Schema::create('school_transfer_requests', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('source_enrollment_id');
            $t->unsignedBigInteger('source_school_id'); $t->unsignedBigInteger('destination_school_id');
            $t->unsignedBigInteger('requested_by'); $t->unsignedBigInteger('guardian_decided_by')->nullable();
            $t->unsignedBigInteger('destination_decided_by')->nullable();
            $t->unsignedBigInteger('destination_section_id')->nullable();
            $t->unsignedBigInteger('destination_enrollment_id')->nullable();
            $t->string('status'); $t->unsignedInteger('version');
            $t->string('idempotency_key')->nullable()->unique(); $t->string('reason')->nullable();
            $t->timestamp('guardian_decided_at')->nullable(); $t->timestamp('destination_decided_at')->nullable();
            $t->timestamp('completed_at')->nullable(); $t->timestamp('expires_at')->nullable(); $t->timestamps();
        });
        Schema::create('school_transfer_events', fn (Blueprint $t) => [
            $t->id(), $t->unsignedBigInteger('transfer_request_id'), $t->unsignedBigInteger('actor_id')->nullable(),
            $t->string('event_type'), $t->string('previous_status')->nullable(), $t->string('next_status'),
            $t->json('metadata')->nullable(), $t->timestamps(),
        ]);
        DB::table('schools')->insert([['id'=>10,'is_active'=>true], ['id'=>11,'is_active'=>true], ['id'=>12,'is_active'=>true]]);
        DB::table('children')->insert([['id'=>1], ['id'=>2]]);
        DB::table('child_parent')->insert([['child_id'=>1,'parent_id'=>30], ['child_id'=>2,'parent_id'=>31]]);
        DB::table('grades')->insert([['id'=>1,'school_id'=>10], ['id'=>2,'school_id'=>11], ['id'=>3,'school_id'=>12]]);
        DB::table('sections')->insert([['id'=>1,'grade_id'=>1,'academic_year_id'=>1], ['id'=>2,'grade_id'=>2,'academic_year_id'=>1], ['id'=>3,'grade_id'=>3,'academic_year_id'=>1]]);
        DB::table('student_enrollments')->insert([
            ['id'=>1,'child_id'=>1,'section_id'=>1,'status'=>'active','enrolled_on'=>'2026-09-01','created_at'=>now(),'updated_at'=>now()],
            ['id'=>2,'child_id'=>2,'section_id'=>1,'status'=>'active','enrolled_on'=>'2026-09-01','created_at'=>now(),'updated_at'=>now()],
        ]);
        DB::table('school_management_assignments')->insert([
            ['school_id'=>10,'user_id'=>20,'role'=>'director'],
            ['school_id'=>11,'user_id'=>21,'role'=>'director'],
            ['school_id'=>12,'user_id'=>22,'role'=>'director'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_transfer_events','school_transfer_requests','school_management_assignments','student_enrollments','sections','grades','child_parent','children','schools','organizations'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function actor(int $id, string $role, array $body = []): Request
    {
        $request = Request::create('/api/school/transfers', 'POST', $body);
        $request->attributes->set('jwt_user', (object) ['id'=>$id, 'role'=>$role]);
        return $request;
    }

    private function initiated(): int
    {
        $response = app(SchoolTransferConsentController::class)->create($this->actor(20, 'teacher', [
            'source_enrollment_id'=>1, 'destination_school_id'=>11,
        ]));
        $this->assertSame(201, $response->getStatusCode());
        return $response->getData(true)['request_id'];
    }

    public function test_foreign_school_cannot_create_transfer_for_source_enrollment(): void
    {
        $response = app(SchoolTransferConsentController::class)->create($this->actor(21, 'teacher', [
            'source_enrollment_id'=>1, 'destination_school_id'=>12,
        ]));
        $this->assertSame(404, $response->getStatusCode());
        $this->assertSame(0, DB::table('school_transfer_requests')->count());
    }

    public function test_guardian_isolation_and_destination_requires_consent(): void
    {
        $id = $this->initiated();
        $controller = app(SchoolTransferConsentController::class);
        $this->assertSame(404, $controller->guardianIndex($this->actor(31,'parent'), 1)->getStatusCode());
        $this->assertSame(404, $controller->guardianDecision($this->actor(31,'parent',['decision'=>'approve','version'=>1]),1,$id)->getStatusCode());
        $destination = app(SchoolTransferDestinationController::class);
        $body = ['decision'=>'accept','version'=>1,'section_id'=>2,'idempotency_key'=>'transfer_key_123456'];
        $this->assertSame(409, $destination->decide($this->actor(21,'teacher',$body),$id)->getStatusCode());
        $this->assertSame(404, $destination->decide($this->actor(22,'teacher',$body),$id)->getStatusCode());
        $this->assertSame(200, $controller->guardianDecision($this->actor(30,'parent',['decision'=>'approve','version'=>1]),1,$id)->getStatusCode());
        $this->assertSame(409, $destination->decide($this->actor(21,'teacher',$body),$id)->getStatusCode());
        $this->assertSame(2, DB::table('student_enrollments')->where('status','active')->count());
    }

    public function test_guardian_rejection_preserves_active_enrollment(): void
    {
        $id = $this->initiated();
        $response = app(SchoolTransferConsentController::class)->guardianDecision(
            $this->actor(30,'parent',['decision'=>'reject','version'=>1]),1,$id
        );
        $this->assertSame('guardian_rejected', $response->getData(true)['status']);
        $this->assertSame('active', DB::table('student_enrollments')->where('id',1)->value('status'));
        $this->assertSame(2, DB::table('student_enrollments')->count());
    }

    public function test_accepted_transfer_preserves_child_identity_and_replay(): void
    {
        $id = $this->initiated();
        app(SchoolTransferConsentController::class)->guardianDecision(
            $this->actor(30,'parent',['decision'=>'approve','version'=>1]),1,$id
        );
        $controller = app(SchoolTransferDestinationController::class);
        $body = ['decision'=>'accept','version'=>2,'section_id'=>2,'idempotency_key'=>'transfer_key_123456'];
        $response = $controller->decide($this->actor(21,'teacher',$body),$id);
        $this->assertSame(201,$response->getStatusCode());
        $enrollmentId = $response->getData(true)['enrollment_id'];
        $this->assertSame('transferred',DB::table('student_enrollments')->where('id',1)->value('status'));
        $this->assertSame(1,(int) DB::table('student_enrollments')->where('id',$enrollmentId)->value('child_id'));
        $this->assertSame(2,DB::table('student_enrollments')->where('status','active')->count());
        $this->assertSame($enrollmentId,$controller->decide($this->actor(21,'teacher',$body),$id)->getData(true)['enrollment_id']);
        $this->assertSame(3,DB::table('student_enrollments')->count());
    }
}
