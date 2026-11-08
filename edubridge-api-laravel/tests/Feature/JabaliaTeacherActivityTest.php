<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaTeacherActivityController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class JabaliaTeacherActivityTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->boolean('is_active');
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('role');
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->boolean('is_active');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id');
        });
        Schema::create('teacher_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('teacher_id');
        });
        Schema::create('jabalia_teacher_activities', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('teacher_id'); $t->date('activity_on');
            $t->string('activity_type'); $t->string('title'); $t->text('summary');
            $t->unsignedBigInteger('recorded_by')->nullable(); $t->timestamps();
        });
        DB::table('organizations')->insert([
            ['id'=>1,'slug'=>'jabalia'],['id'=>2,'slug'=>'other'],
        ]);
        DB::table('schools')->insert([
            ['id'=>10,'organization_id'=>1,'is_active'=>true],
            ['id'=>11,'organization_id'=>1,'is_active'=>true],
            ['id'=>12,'organization_id'=>2,'is_active'=>true],
        ]);
        DB::table('users')->insert([
            ['id'=>20,'name'=>'Teacher A','role'=>'teacher'],
            ['id'=>21,'name'=>'Teacher B','role'=>'teacher'],
            ['id'=>22,'name'=>'Teacher C','role'=>'teacher'],
            ['id'=>23,'name'=>'Director','role'=>'director'],
            ['id'=>30,'name'=>'Institution User','role'=>'institution'],
        ]);
        DB::table('organization_user')->insert([
            ['organization_id'=>1,'user_id'=>20,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>1,'user_id'=>21,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>2,'user_id'=>22,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>1,'user_id'=>23,'role'=>'teacher','is_active'=>true],
        ]);
        DB::table('grades')->insert([
            ['id'=>1,'school_id'=>10],['id'=>2,'school_id'=>11],['id'=>3,'school_id'=>12],
        ]);
        DB::table('sections')->insert([
            ['id'=>1,'grade_id'=>1],['id'=>2,'grade_id'=>2],['id'=>3,'grade_id'=>3],
        ]);
        DB::table('teacher_assignments')->insert([
            ['section_id'=>1,'teacher_id'=>20], ['section_id'=>2,'teacher_id'=>21],
            ['section_id'=>3,'teacher_id'=>22],['section_id'=>1,'teacher_id'=>23],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_teacher_activities','teacher_assignments','sections','grades',
            'organization_user','users','schools','organizations'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function request(array $data = [], int $org = 1, string $slug = 'jabalia', string $role = 'institution'): Request
    {
        $r = Request::create('/api/institutions/'.$slug.'/schools/10/teacher-activities', 'POST', $data);
        $r->attributes->set('organization', (object)['id'=>$org,'slug'=>$slug]);
        $r->attributes->set('jwt_user', (object)['id'=>30,'role'=>$role]);
        return $r;
    }

    private function payload(): array
    {
        return [
            'teacher_id'=>20, 'activity_on'=>now()->subDay()->toDateString(),
            'activity_type'=>'classroom_activity', 'title'=>'Visual reading workshop',
            'summary'=>'Facilitated a classroom reading activity using approved visual materials.',
        ];
    }

    public function test_teacher_activity_is_internal_and_only_school_assigned_teacher_can_be_recorded(): void
    {
        $controller = app(JabaliaTeacherActivityController::class);
        $created = $controller->store($this->request($this->payload()), 'jabalia', 10);
        $this->assertSame(201, $created->status());
        $this->assertSame('institution_only', $created->getData(true)['privacy']);
        $this->assertSame(30, DB::table('jabalia_teacher_activities')->value('recorded_by'));
        $report = $controller->index($this->request(), 'jabalia', 10)->getData(true);
        $this->assertSame([20], array_column($report['teachers'], 'id'));
        $this->assertCount(1, $report['activities']['data']);
        $this->assertSame('Teacher A', $report['activities']['data'][0]['teacher_name']);
        $this->assertSame('institution_only', $report['privacy']);
        $this->assertCount(0, $controller->index($this->request(), 'jabalia', 11)
            ->getData(true)['activities']['data']);
    }

    public function test_cross_school_organization_and_non_teacher_identity_are_denied(): void
    {
        $controller = app(JabaliaTeacherActivityController::class);
        $payload = $this->payload();
        foreach ([21,22,23,999] as $teacher) {
            $payload['teacher_id'] = $teacher;
            $this->assertSame(404, $controller->store($this->request($payload), 'jabalia', 10)->status());
        }
        $payload = $this->payload();
        $this->assertSame(404, $controller->store($this->request($payload), 'jabalia', 11)->status());
        $this->assertSame(404, $controller->store($this->request($payload, 2, 'other'), 'other', 12)->status());
        $this->assertSame(404, $controller->store($this->request($payload, 1, 'jabalia', 'parent'), 'jabalia', 10)->status());
        $this->assertSame(404, $controller->index($this->request([],1,'jabalia','school'), 'jabalia', 10)->status());
        DB::table('organization_user')->where('user_id',20)->update(['is_active'=>false]);
        $this->assertSame(404, $controller->store($this->request($this->payload()), 'jabalia', 10)->status());
        $this->assertSame(0, DB::table('jabalia_teacher_activities')->count());
    }

    public function test_invalid_future_date_and_blank_summary_do_not_create_reports(): void
    {
        $controller = app(JabaliaTeacherActivityController::class);
        $payload = $this->payload();
        $payload['activity_on'] = now()->addDay()->toDateString();
        try {
            $controller->store($this->request($payload), 'jabalia', 10);
            $this->fail('Future dates should be rejected');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('activity_on', $e->errors());
        }
        $payload = $this->payload();
        $payload['summary'] = '            ';
        try {
            $controller->store($this->request($payload), 'jabalia', 10);
            $this->fail('Whitespace-only summary should be rejected');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('summary', $e->errors());
        }
        $this->assertSame(0, DB::table('jabalia_teacher_activities')->count());
    }

    public function test_no_anonymous_access_to_report_or_create(): void
    {
        $url = '/api/institutions/jabalia/schools/10/teacher-activities';
        foreach (['GET','POST'] as $method) {
            $this->assertContains($this->json($method, $url)->status(), [401,403]);
        }
    }
}
