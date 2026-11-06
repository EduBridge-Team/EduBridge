<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaContractReadinessController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaContractReadinessTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
        });
        Schema::create('jabalia_teacher_documents', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('teacher_id');
            $t->string('type'); $t->string('storage_path')->nullable();
            $t->date('expires_on')->nullable();
        });
        DB::table('organizations')->insert([
            ['id'=>1, 'slug'=>'jabalia'], ['id'=>2, 'slug'=>'other'],
        ]);
        DB::table('schools')->insert([
            ['id'=>1,'organization_id'=>1], ['id'=>2,'organization_id'=>1], ['id'=>3,'organization_id'=>2],
        ]);
        DB::table('jabalia_teacher_documents')->insert([
            ['organization_id'=>1,'school_id'=>1,'teacher_id'=>10,'type'=>'contract',
                'storage_path'=>'jabalia-teacher-documents/file.pdf','expires_on'=>now()->subDay()->toDateString()],
            ['organization_id'=>1,'school_id'=>1,'teacher_id'=>11,'type'=>'contract',
                'storage_path'=>null,'expires_on'=>null],
            ['organization_id'=>1,'school_id'=>1,'teacher_id'=>10,'type'=>'identity_document',
                'storage_path'=>'jabalia-teacher-documents/id.pdf','expires_on'=>null],
            ['organization_id'=>1,'school_id'=>2,'teacher_id'=>11,'type'=>'contract',
                'storage_path'=>'jabalia-teacher-documents/other.pdf','expires_on'=>null],
            ['organization_id'=>2,'school_id'=>3,'teacher_id'=>12,'type'=>'contract',
                'storage_path'=>'jabalia-teacher-documents/foreign.pdf','expires_on'=>null],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('jabalia_teacher_contract_periods');
        Schema::dropIfExists('jabalia_teacher_documents');
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    private function request(string $role = 'institution', int $org = 1, string $slug = 'jabalia'): Request
    {
        $req = Request::create('/api/institutions/'.$slug.'/schools/1/contract-readiness');
        $req->attributes->set('organization', (object)['id'=>$org,'slug'=>$slug]);
        $req->attributes->set('jwt_user', (object)['id'=>30,'role'=>$role]);
        return $req;
    }

    public function test_only_contract_records_from_the_selected_school_are_aggregated(): void
    {
        $controller = app(JabaliaContractReadinessController::class);
        $response = $controller->index($this->request(), 'jabalia', 1);
        $this->assertSame(200, $response->status());
        $data = $response->getData(true);
        $this->assertSame(2, $data['contract_records']);
        $this->assertSame(1, $data['records_with_attached_path']);
        $this->assertSame(1, $data['metadata_only_records']);
        $this->assertSame(1, $data['records_expired_by_date']);
        $this->assertSame(1, $data['records_without_expiry_date']);
        $this->assertSame(2, $data['teachers_with_contract_records']);
        $this->assertFalse($data['attachment_integrity_verified']);
        $this->assertArrayNotHasKey('storage_path', $data);
        $this->assertArrayNotHasKey('teacher_id', $data);
    }

    public function test_other_school_and_organization_counts_do_not_leak(): void
    {
        $controller = app(JabaliaContractReadinessController::class);
        $otherSchool = $controller->index($this->request(), 'jabalia', 2)->getData(true);
        $this->assertSame(1, $otherSchool['contract_records']);
        $this->assertSame(404, $controller->index($this->request(), 'jabalia', 3)->status());
        $this->assertSame(404, $controller->index($this->request('parent'), 'jabalia', 1)->status());
        $this->assertSame(404, $controller->index($this->request('school'), 'jabalia', 1)->status());
        $this->assertSame(404, $controller->index($this->request('institution', 2, 'other'), 'other', 3)->status());
    }

    public function test_contract_period_counts_are_scoped_and_use_recorded_calendar_dates_only(): void
    {
        Schema::create('jabalia_teacher_contract_periods', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('teacher_id'); $t->unsignedBigInteger('previous_period_id')->nullable();
            $t->date('starts_on'); $t->date('ends_on');
        });
        $today=now('Asia/Hebron')->toDateString();
        DB::table('jabalia_teacher_contract_periods')->insert([
            ['organization_id'=>1,'school_id'=>1,'teacher_id'=>10,'previous_period_id'=>null,
                'starts_on'=>now('Asia/Hebron')->subMonths(2)->toDateString(),
                'ends_on'=>now('Asia/Hebron')->subDay()->toDateString()],
            ['organization_id'=>1,'school_id'=>1,'teacher_id'=>10,'previous_period_id'=>1,
                'starts_on'=>$today,
                'ends_on'=>now('Asia/Hebron')->addDays(12)->toDateString()],
            ['organization_id'=>1,'school_id'=>1,'teacher_id'=>11,'previous_period_id'=>null,
                'starts_on'=>now('Asia/Hebron')->addMonth()->toDateString(),
                'ends_on'=>now('Asia/Hebron')->addMonths(3)->toDateString()],
            ['organization_id'=>1,'school_id'=>2,'teacher_id'=>11,'previous_period_id'=>null,
                'starts_on'=>$today,'ends_on'=>now('Asia/Hebron')->addDays(5)->toDateString()],
            ['organization_id'=>2,'school_id'=>3,'teacher_id'=>12,'previous_period_id'=>null,
                'starts_on'=>$today,'ends_on'=>now('Asia/Hebron')->addDays(4)->toDateString()],
        ]);
        $controller=app(JabaliaContractReadinessController::class);
        $data=$controller->index($this->request(),'jabalia',1)->getData(true);
        $this->assertTrue($data['contract_periods_available']);
        $this->assertSame(3,$data['periods_recorded']);
        $this->assertSame(1,$data['periods_current_by_date']);
        $this->assertSame(1,$data['periods_ended_by_date']);
        $this->assertSame(1,$data['periods_upcoming_by_date']);
        $this->assertSame(1,$data['periods_ending_within_30_days']);
        $this->assertSame(1,$data['renewals_recorded']);
        $this->assertArrayNotHasKey('teacher_id',$data);
        $this->assertArrayNotHasKey('project_name',$data);
        $other=$controller->index($this->request(),'jabalia',2)->getData(true);
        $this->assertSame(1,$other['periods_current_by_date']);
        $this->assertSame(1,$other['periods_recorded']);
    }

    public function test_anonymous_http_report_cannot_be_read(): void
    {
        $response = $this->getJson('/api/institutions/jabalia/schools/1/contract-readiness');
        $this->assertContains($response->status(), [401,403]);
    }
}
