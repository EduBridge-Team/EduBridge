<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaAdmissionReadinessController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaAdmissionReadinessTest extends TestCase
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
            $t->unsignedInteger('version')->default(1); $t->string('status'); $t->timestamps();
        });
        Schema::create('jabalia_admission_documents', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('child_id');
            $t->unsignedBigInteger('enrollment_request_id'); $t->string('type');
            $t->string('storage_path')->nullable();
        });
        DB::table('organizations')->insert([
            ['id'=>1, 'slug'=>'jabalia', 'is_active'=>true],
            ['id'=>2, 'slug'=>'other', 'is_active'=>true],
        ]);
        DB::table('schools')->insert([
            ['id'=>10, 'organization_id'=>1,'is_active'=>true],
            ['id'=>11, 'organization_id'=>1,'is_active'=>true],
            ['id'=>12, 'organization_id'=>2,'is_active'=>true],
        ]);
        DB::table('school_management_assignments')->insert([
            ['id'=>1,'school_id'=>10,'user_id'=>101,'role'=>'director','permissions'=>null,'ends_at'=>null],
            ['id'=>2,'school_id'=>10,'user_id'=>102,'role'=>'deputy_director','permissions'=>json_encode(['enrollment']),'ends_at'=>null],
            ['id'=>3,'school_id'=>10,'user_id'=>103,'role'=>'deputy_director','permissions'=>json_encode(['attendance']),'ends_at'=>null],
            ['id'=>4,'school_id'=>12,'user_id'=>104,'role'=>'director','permissions'=>null,'ends_at'=>null],
            ['id'=>5,'school_id'=>11,'user_id'=>105,'role'=>'director','permissions'=>null,'ends_at'=>null],
            ['id'=>6,'school_id'=>10,'user_id'=>106,'role'=>'director','permissions'=>null,'ends_at'=>now()],
        ]);
        DB::table('school_accounts')->insert(['school_id'=>10,'user_id'=>107]);
        $stamp = ['created_at'=>now(),'updated_at'=>now()];
        DB::table('school_enrollment_requests')->insert([
            ['id'=>201,'school_id'=>10,'child_id'=>1,'version'=>3,'status'=>'pending',...$stamp],
            ['id'=>202,'school_id'=>10,'child_id'=>2,'version'=>1,'status'=>'pending',...$stamp],
            ['id'=>203,'school_id'=>10,'child_id'=>3,'version'=>2,'status'=>'rejected',...$stamp],
            ['id'=>204,'school_id'=>11,'child_id'=>4,'version'=>1,'status'=>'pending',...$stamp],
            ['id'=>205,'school_id'=>12,'child_id'=>5,'version'=>1,'status'=>'pending',...$stamp],
        ]);
        foreach (['audiology_report','birth_certificate','medical_report','child_photo','father_identity'] as $i => $type) {
            DB::table('jabalia_admission_documents')->insert([
                'school_id'=>10, 'child_id'=>1, 'enrollment_request_id'=>201,
                'type'=>$type, 'storage_path'=>'private/secret-'.($i+1),
            ]);
        }
        DB::table('jabalia_admission_documents')->insert([
            ['school_id'=>10,'child_id'=>1,'enrollment_request_id'=>201,'type'=>'audiology_report','storage_path'=>'private/duplicate'],
            ['school_id'=>10,'child_id'=>2,'enrollment_request_id'=>202,'type'=>'birth_certificate','storage_path'=>'private/other'],
            ['school_id'=>10,'child_id'=>3,'enrollment_request_id'=>203,'type'=>'audiology_report','storage_path'=>'private/rejected'],
            ['school_id'=>11,'child_id'=>4,'enrollment_request_id'=>204,'type'=>'audiology_report','storage_path'=>'private/foreign-school'],
            ['school_id'=>12,'child_id'=>5,'enrollment_request_id'=>205,'type'=>'audiology_report','storage_path'=>'private/foreign-tenant'],
            // Deliberately corrupt metadata: matching request ID but different child.
            ['school_id'=>10,'child_id'=>99,'enrollment_request_id'=>202,'type'=>'medical_report','storage_path'=>'private/wrong-child'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_admission_documents','school_enrollment_requests',
            'school_accounts','school_management_assignments','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function actor(int $id, string $role = 'teacher'): Request
    {
        $request = Request::create('/api/school/jabalia/admission-readiness', 'GET');
        $request->attributes->set('jwt_user', (object)['id'=>$id,'role'=>$role]);
        return $request;
    }

    public function test_only_pending_same_school_metadata_is_listed_without_approvals_or_paths(): void
    {
        config()->set('services.jabalia_admissions.upload_enabled', false);
        $res = app(JabaliaAdmissionReadinessController::class)->index($this->actor(101));
        $this->assertSame(200, $res->status());
        $data = $res->getData(true);
        $this->assertSame(10, $data['school_id']);
        $this->assertFalse($data['approval_allowed']);
        $this->assertFalse($data['upload_enabled']);
        $this->assertSame([201,202], array_column($data['items'], 'request_id'));
        $complete = $data['items'][0];
        $this->assertSame(3, $complete['version']);
        $this->assertTrue($complete['evidence_categories_recorded']);
        $this->assertSame([], $complete['missing_types']);
        $this->assertFalse($complete['counselor_review_completed']);
        $this->assertFalse($complete['administration_approved']);
        $incomplete = $data['items'][1];
        $this->assertFalse($incomplete['evidence_categories_recorded']);
        $this->assertSame(['audiology_report','medical_report','child_photo','father_identity'],
            $incomplete['missing_types']);
        $serialized = json_encode($data);
        foreach (['storage_path','private/','mime_type','file_size','original_filename','requester_email'] as $secret) {
            $this->assertStringNotContainsString($secret, $serialized);
        }
    }

    public function test_delegated_enrollment_deputy_allowed_but_others_and_revoked_denied(): void
    {
        $controller = app(JabaliaAdmissionReadinessController::class);
        $this->assertSame(200, $controller->index($this->actor(102))->status());
        foreach ([
            $this->actor(103), $this->actor(104), $this->actor(107,'school'),
            $this->actor(106), $this->actor(999,'parent'),
        ] as $request) {
            $this->assertSame(404, $controller->index($request)->status());
        }
        DB::table('school_management_assignments')->where('user_id',102)->update(['ends_at'=>now()]);
        $this->assertSame(404, $controller->index($this->actor(102))->status());
        $other = $controller->index($this->actor(105))->getData(true);
        $this->assertSame(11, $other['school_id']);
        $this->assertSame([204], array_column($other['items'], 'request_id'));
        $this->assertFalse($other['items'][0]['evidence_categories_recorded']);
    }

    public function test_missing_evidence_table_fails_closed_and_never_changes_application_status(): void
    {
        Schema::dropIfExists('jabalia_admission_documents');
        $res = app(JabaliaAdmissionReadinessController::class)->index($this->actor(101));
        $this->assertSame(503, $res->status());
        $this->assertSame('pending', DB::table('school_enrollment_requests')->where('id', 201)->value('status'));
    }

    public function test_anonymous_http_route_is_protected(): void
    {
        $res = $this->getJson('/api/school/jabalia/admission-readiness');
        $this->assertContains($res->status(), [401,403]);
    }
}
