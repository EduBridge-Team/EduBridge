<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaAdmissionIntakeTriageController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class JabaliaAdmissionIntakeTriageTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug'); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->boolean('is_active')->default(true);
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->json('permissions')->nullable(); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
        });
        Schema::create('school_enrollment_requests', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->unsignedInteger('version')->default(1); $t->timestamps();
        });
        Schema::create('jabalia_admission_intake_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('enrollment_request_id'); $t->unsignedBigInteger('child_id');
            $t->unsignedInteger('request_version'); $t->string('state');
            $t->unsignedBigInteger('actor_id')->nullable(); $t->string('management_role');
            $t->timestamp('created_at');
        });

        DB::table('organizations')->insert([
            ['id'=>1, 'slug'=>'jabalia', 'is_active'=>true],
            ['id'=>2, 'slug'=>'elsewhere', 'is_active'=>true],
        ]);
        DB::table('schools')->insert([
            ['id'=>10, 'organization_id'=>1, 'is_active'=>true],
            ['id'=>11, 'organization_id'=>1, 'is_active'=>true],
            ['id'=>12, 'organization_id'=>2, 'is_active'=>true],
            ['id'=>13, 'organization_id'=>1, 'is_active'=>false],
        ]);
        DB::table('school_management_assignments')->insert([
            ['id'=>1,'school_id'=>10,'user_id'=>101,'role'=>'director','permissions'=>null,'ends_at'=>null],
            ['id'=>2,'school_id'=>10,'user_id'=>102,'role'=>'deputy_director','permissions'=>json_encode(['enrollment']),'ends_at'=>null],
            ['id'=>3,'school_id'=>10,'user_id'=>103,'role'=>'deputy_director','permissions'=>json_encode(['attendance']),'ends_at'=>null],
            ['id'=>4,'school_id'=>11,'user_id'=>104,'role'=>'director','permissions'=>null,'ends_at'=>null],
            ['id'=>5,'school_id'=>12,'user_id'=>105,'role'=>'director','permissions'=>null,'ends_at'=>null],
            ['id'=>6,'school_id'=>10,'user_id'=>106,'role'=>'director','permissions'=>null,'ends_at'=>now()],
            ['id'=>7,'school_id'=>13,'user_id'=>108,'role'=>'director','permissions'=>null,'ends_at'=>null],
        ]);
        DB::table('school_accounts')->insert(['school_id'=>10,'user_id'=>107]);
        $stamp=['created_at'=>now(),'updated_at'=>now()];
        DB::table('school_enrollment_requests')->insert([
            ['id'=>201,'school_id'=>10,'child_id'=>1,'status'=>'pending','version'=>3,...$stamp],
            ['id'=>202,'school_id'=>10,'child_id'=>2,'status'=>'pending','version'=>1,...$stamp],
            ['id'=>203,'school_id'=>10,'child_id'=>3,'status'=>'rejected','version'=>2,...$stamp],
            ['id'=>204,'school_id'=>11,'child_id'=>4,'status'=>'pending','version'=>1,...$stamp],
            ['id'=>205,'school_id'=>12,'child_id'=>5,'status'=>'pending','version'=>1,...$stamp],
            ['id'=>206,'school_id'=>13,'child_id'=>6,'status'=>'pending','version'=>1,...$stamp],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_admission_intake_events','school_enrollment_requests',
            'school_accounts','school_management_assignments','schools','organizations'] as $name) {
            Schema::dropIfExists($name);
        }
        parent::tearDown();
    }

    private function actor(int $user=101, string $role='director', array $input=[]): Request
    {
        $request = Request::create('/api/school/jabalia/enrollment-requests/201/intake-triage', 'POST', $input);
        $request->attributes->set('jwt_user', (object)['id'=>$user,'role'=>$role]);
        return $request;
    }

    private function payload(string $state='evidence_followup_needed', int $expectedEvent=0,
        int $expectedVersion=3): array
    {
        return [
            'state'=>$state,
            'expected_event_id'=>$expectedEvent,
            'expected_request_version'=>$expectedVersion,
        ];
    }

    public function test_director_and_enrollment_deputy_can_log_non_decisional_triage_with_audit(): void
    {
        $controller=app(JabaliaAdmissionIntakeTriageController::class);
        $initial=$controller->show($this->actor(),201)->getData(true);
        $this->assertSame(10,$initial['school_id']);
        $this->assertSame('untracked',$initial['current_state']);
        $this->assertSame(0,$initial['latest_event_id']);
        $this->assertFalse($initial['approval_allowed']);
        $this->assertFalse($initial['counselor_review_completed']);
        $this->assertSame(3,$initial['request_version']);

        $one=$controller->store($this->actor(101,'director',
            $this->payload()),201);
        $this->assertSame(200,$one->status());
        $this->assertSame('evidence_followup_needed',$one->getData(true)['current_state']);
        $eventId=$one->getData(true)['latest_event_id'];
        $this->assertGreaterThan(0,$eventId);
        $this->assertDatabaseHas('jabalia_admission_intake_events',[
            'school_id'=>10,'organization_id'=>1,'enrollment_request_id'=>201,
            'child_id'=>1,'request_version'=>3,'actor_id'=>101,
            'management_role'=>'director','state'=>'evidence_followup_needed',
        ]);

        $two=$controller->store($this->actor(102,'teacher',
            $this->payload('awaiting_counselor_assignment',$eventId)),201);
        $this->assertSame(200,$two->status());
        $events=$two->getData(true)['events']['data'];
        $this->assertCount(2,$events);
        $this->assertSame('deputy_director',$events[0]['management_role']);
        $this->assertSame(102,$events[0]['actor_id']);
        foreach ($events as $event) {
            $this->assertArrayNotHasKey('medical_notes',$event);
            $this->assertArrayNotHasKey('storage_path',$event);
            $this->assertArrayNotHasKey('reason',$event);
            $this->assertArrayNotHasKey('child_name',$event);
        }
        $this->assertSame('pending',DB::table('school_enrollment_requests')->where('id',201)->value('status'));
        $this->assertSame(3,DB::table('school_enrollment_requests')->where('id',201)->value('version'));
        $this->assertSame(2,DB::table('jabalia_admission_intake_events')->count());
    }

    public function test_cross_school_unapproved_role_and_revoked_access_denied(): void
    {
        $controller=app(JabaliaAdmissionIntakeTriageController::class);
        foreach ([
            [103,'teacher',201],[104,'director',201],[105,'director',201],
            [106,'director',201],[107,'school',201],[999,'parent',201],
            [101,'director',204],[101,'director',205],[101,'director',203],
            [108,'director',206],
        ] as [$id,$role,$request]) {
            $this->assertSame(404,$controller->show($this->actor($id,$role),$request)->status());
            $this->assertSame(404,$controller->store(
                $this->actor($id,$role,$this->payload()),$request)->status());
        }
        $this->assertSame(0,DB::table('jabalia_admission_intake_events')->count());
        DB::table('school_management_assignments')->where('user_id',102)->update(['ends_at'=>now()]);
        $this->assertSame(404,$controller->show($this->actor(102),201)->status());
    }

    public function test_concurrent_triage_and_application_revision_conflicts_fail_closed(): void
    {
        $controller=app(JabaliaAdmissionIntakeTriageController::class);
        $this->assertSame(200,$controller->store(
            $this->actor(101,'director',$this->payload()),201)->status());
        $this->assertSame(409,$controller->store(
            $this->actor(101,'director',$this->payload('administrative_followup_needed',0)),201)->status());
        $this->assertSame(409,$controller->store(
            $this->actor(101,'director',$this->payload('evidence_followup_needed',1)),201)->status());
        DB::table('school_enrollment_requests')->where('id',201)->update(['version'=>4]);
        $this->assertSame(409,$controller->store(
            $this->actor(101,'director',$this->payload('administrative_followup_needed',1)),201)->status());
        DB::table('school_enrollment_requests')->where('id',201)->update(['status'=>'cancelled']);
        $this->assertSame(404,$controller->store(
            $this->actor(101,'director',$this->payload('administrative_followup_needed',1,4)),201)->status());
        $this->assertSame(1,DB::table('jabalia_admission_intake_events')->count());
    }

    public function test_invalid_clinical_or_final_decision_values_never_enter_intake_audit(): void
    {
        $controller=app(JabaliaAdmissionIntakeTriageController::class);
        try {
            $controller->store($this->actor(101,'director',$this->payload('approved')),201);
            $this->fail('Final approval must be rejected');
        } catch (ValidationException $error) {
            $this->assertArrayHasKey('state',$error->errors());
        }
        $this->assertSame(0,DB::table('jabalia_admission_intake_events')->count());
    }

    public function test_missing_intake_schema_fails_closed(): void
    {
        Schema::dropIfExists('jabalia_admission_intake_events');
        $controller=app(JabaliaAdmissionIntakeTriageController::class);
        $this->assertSame(503,$controller->show($this->actor(),201)->status());
        $this->assertSame(503,$controller->store(
            $this->actor(101,'director',$this->payload()),201)->status());
    }

    public function test_unauthenticated_routes_require_login(): void
    {
        $url='/api/school/jabalia/enrollment-requests/201/intake-triage';
        $this->assertContains($this->getJson($url)->status(),[401,403]);
        $this->assertContains($this->postJson($url,$this->payload())->status(),[401,403]);
    }
}
