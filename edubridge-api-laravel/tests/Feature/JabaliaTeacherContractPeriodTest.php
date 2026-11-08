<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaTeacherContractPeriodController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class JabaliaTeacherContractPeriodTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->boolean('is_active')->default(true);
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('user_id'); $t->string('role');
            $t->boolean('is_active')->default(true);
        });
        Schema::create('jabalia_teacher_documents', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('teacher_id');
            $t->string('type'); $t->string('title');
            $t->string('storage_path')->nullable();
        });
        Schema::create('jabalia_teacher_document_access_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('teacher_id');
            $t->unsignedBigInteger('document_id')->nullable(); $t->string('action');
            $t->unsignedBigInteger('actor_id')->nullable(); $t->timestamp('created_at');
        });
        Schema::create('jabalia_teacher_contract_periods', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('teacher_id');
            $t->unsignedBigInteger('contract_document_id')->unique();
            $t->unsignedBigInteger('previous_period_id')->nullable()->unique();
            $t->string('project_name'); $t->date('starts_on'); $t->date('ends_on');
            $t->date('signed_on')->nullable();
            $t->unsignedBigInteger('recorded_by')->nullable(); $t->timestamp('created_at');
        });

        DB::table('schools')->insert([
            ['id'=>10,'organization_id'=>1,'is_active'=>true],
            ['id'=>11,'organization_id'=>1,'is_active'=>true],
            ['id'=>12,'organization_id'=>2,'is_active'=>true],
            ['id'=>13,'organization_id'=>1,'is_active'=>false],
        ]);
        DB::table('organization_user')->insert([
            ['organization_id'=>1,'user_id'=>20,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>1,'user_id'=>21,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>2,'user_id'=>22,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>1,'user_id'=>23,'role'=>'teacher','is_active'=>false],
        ]);
        foreach ([1,2,3,4,5] as $i) {
            Storage::disk('local')->put("jabalia-teacher-documents/contract-{$i}.pdf", "%PDF fake {$i}");
        }
        DB::table('jabalia_teacher_documents')->insert([
            ['id'=>1,'organization_id'=>1,'school_id'=>10,'teacher_id'=>20,
                'type'=>'contract','title'=>'Original','storage_path'=>'jabalia-teacher-documents/contract-1.pdf'],
            ['id'=>2,'organization_id'=>1,'school_id'=>10,'teacher_id'=>20,
                'type'=>'contract','title'=>'Renewed','storage_path'=>'jabalia-teacher-documents/contract-2.pdf'],
            ['id'=>3,'organization_id'=>1,'school_id'=>11,'teacher_id'=>21,
                'type'=>'contract','title'=>'Foreign school','storage_path'=>'jabalia-teacher-documents/contract-3.pdf'],
            ['id'=>4,'organization_id'=>2,'school_id'=>12,'teacher_id'=>22,
                'type'=>'contract','title'=>'Other organization','storage_path'=>'jabalia-teacher-documents/contract-4.pdf'],
            ['id'=>5,'organization_id'=>1,'school_id'=>10,'teacher_id'=>20,
                'type'=>'university_degree','title'=>'Not a contract','storage_path'=>'jabalia-teacher-documents/contract-5.pdf'],
            ['id'=>6,'organization_id'=>1,'school_id'=>10,'teacher_id'=>20,
                'type'=>'contract','title'=>'No upload','storage_path'=>null],
            ['id'=>7,'organization_id'=>1,'school_id'=>10,'teacher_id'=>20,
                'type'=>'contract','title'=>'Missing physical copy','storage_path'=>'jabalia-teacher-documents/missing.pdf'],
            ['id'=>8,'organization_id'=>1,'school_id'=>13,'teacher_id'=>20,
                'type'=>'contract','title'=>'Inactive school','storage_path'=>'jabalia-teacher-documents/contract-3.pdf'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_teacher_contract_periods','jabalia_teacher_document_access_events',
            'jabalia_teacher_documents','organization_user','schools'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function req(array $data=[], int $organization=1, string $slug='jabalia',
        string $role='institution'): Request
    {
        $request=Request::create('/api/institutions/'.$slug.'/schools/10/teachers/20/contract-periods',
            'POST', $data);
        $request->attributes->set('organization',(object)['id'=>$organization,'slug'=>$slug]);
        $request->attributes->set('jwt_user',(object)['id'=>99,'role'=>$role]);
        return $request;
    }

    private function form(int $document=1, ?int $previous=null, string $from='2026-01-01',
        string $until='2026-06-30'): array
    {
        return [
            'contract_document_id'=>$document, 'previous_period_id'=>$previous,
            'project_name'=>'Temporary literacy project',
            'starts_on'=>$from, 'ends_on'=>$until, 'signed_on'=>'2026-01-01',
        ];
    }

    private function controller(): JabaliaTeacherContractPeriodController
    {
        return app(JabaliaTeacherContractPeriodController::class);
    }

    public function test_records_private_contract_period_and_immutable_renewal_lineage(): void
    {
        $first=$this->controller()->store($this->req($this->form()),'jabalia',10,20);
        $this->assertSame(201,$first->status());
        $firstId=$first->getData(true)['period']['id'];
        $this->assertDatabaseHas('jabalia_teacher_document_access_events',[
            'action'=>'contract_period_recorded','document_id'=>1,'actor_id'=>99,
        ]);
        $this->assertSame(409,$this->controller()->store(
            $this->req($this->form()),'jabalia',10,20)->status());
        $renew=$this->controller()->store($this->req($this->form(
            2,$firstId,'2026-07-01','2026-12-31'
        )),'jabalia',10,20);
        $this->assertSame(201,$renew->status());
        $this->assertSame($firstId,$renew->getData(true)['period']['previous_period_id']);
        $this->assertDatabaseCount('jabalia_teacher_contract_periods',2);

        $list=$this->controller()->index($this->req(),'jabalia',10,20);
        $this->assertSame(200,$list->status());
        $summary=$list->getData(true);
        $this->assertTrue($summary['immutable']);
        $this->assertFalse($summary['employment_legally_verified']);
        $this->assertFalse($summary['attachment_integrity_verified']);
        $this->assertCount(2,$summary['periods']['data']);
        $this->assertSame('Temporary literacy project',$summary['periods']['data'][0]['project_name']);
        $this->assertSame(2,$summary['periods']['data'][0]['contract_document_id']);
        $json=json_encode($summary);
        foreach (['storage_path','original_filename','file_size','contract-1.pdf','private/'] as $secret) {
            $this->assertStringNotContainsString($secret,$json);
        }
        $this->assertDatabaseHas('jabalia_teacher_document_access_events',[
            'action'=>'contract_periods_listed','document_id'=>null,'actor_id'=>99,
        ]);
        $this->assertSame(2,DB::table('jabalia_teacher_contract_periods')->count());
    }

    public function test_rejects_foreign_school_teacher_role_and_inactive_membership(): void
    {
        $controller=$this->controller();
        foreach ([
            [$this->req($this->form(3)),10,20],
            [$this->req($this->form(4)),10,20],
            [$this->req($this->form(5)),10,20],
            [$this->req($this->form(1)),11,20],
            [$this->req($this->form(8)),13,20],
        ] as [$request,$school,$teacher]) {
            $this->assertContains($controller->store($request,'jabalia',$school,$teacher)->status(),
                [404,422]);
        }
        foreach (['teacher','director','school','parent','specialist'] as $role) {
            $this->assertSame(404,$controller->index(
                $this->req([],1,'jabalia',$role),'jabalia',10,20)->status());
            $this->assertSame(404,$controller->store(
                $this->req($this->form(),1,'jabalia',$role),'jabalia',10,20)->status());
        }
        $this->assertSame(404,$controller->store($this->req($this->form(),2,'other'),
            'other',10,20)->status());
        $this->assertSame(404,$controller->index($this->req(), 'jabalia',10,23)->status());
        $this->assertDatabaseCount('jabalia_teacher_contract_periods',0);
    }

    public function test_unattached_or_missing_private_file_is_not_a_recorded_contract(): void
    {
        $this->assertSame(422,$this->controller()->store(
            $this->req($this->form(6)),'jabalia',10,20)->status());
        $this->assertSame(409,$this->controller()->store(
            $this->req($this->form(7)),'jabalia',10,20)->status());
        $this->assertDatabaseCount('jabalia_teacher_contract_periods',0);
        $this->assertDatabaseCount('jabalia_teacher_document_access_events',0);
    }

    public function test_renewal_cannot_be_cross_school_backdated_or_linked_twice(): void
    {
        $first=$this->controller()->store($this->req($this->form()),'jabalia',10,20)
            ->getData(true)['period']['id'];
        $this->assertSame(422,$this->controller()->store(
            $this->req($this->form(2,$first,'2026-06-01','2026-12-31')),'jabalia',10,20)->status());

        // The same document may be registered only once.
        $this->assertSame(409,$this->controller()->store(
            $this->req($this->form()),'jabalia',10,20)->status());

        $this->assertSame(404,$this->controller()->store(
            $this->req($this->form(3,$first,'2026-07-01','2026-12-31')),
            'jabalia',11,21)->status());
        $this->assertSame(201,$this->controller()->store(
            $this->req($this->form(2,$first,'2026-07-01','2026-12-31')),
            'jabalia',10,20)->status());
        $this->assertDatabaseCount('jabalia_teacher_contract_periods',2);
    }

    public function test_invalid_date_period_fails_before_insert(): void
    {
        $input=$this->form();
        $input['ends_on']='2025-01-01';
        try {
            $this->controller()->store($this->req($input),'jabalia',10,20);
            $this->fail('Expected a validation error');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('ends_on',$e->errors());
        }
        $this->assertDatabaseCount('jabalia_teacher_contract_periods',0);
    }

    public function test_missing_contract_period_table_returns_503_without_any_write(): void
    {
        Schema::dropIfExists('jabalia_teacher_contract_periods');
        $this->assertSame(503,$this->controller()->index(
            $this->req(),'jabalia',10,20)->status());
        $this->assertSame(503,$this->controller()->store(
            $this->req($this->form()),'jabalia',10,20)->status());
        $this->assertDatabaseCount('jabalia_teacher_document_access_events',0);
    }

    public function test_anonymous_endpoints_require_authentication(): void
    {
        $url='/api/institutions/jabalia/schools/10/teachers/20/contract-periods';
        $this->assertContains($this->getJson($url)->status(),[401,403]);
        $this->assertContains($this->postJson($url,$this->form())->status(),[401,403]);
    }
}
