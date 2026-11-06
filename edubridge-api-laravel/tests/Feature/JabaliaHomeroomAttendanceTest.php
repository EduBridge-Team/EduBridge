<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaHomeroomAttendanceController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaHomeroomAttendanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug'); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->string('name');
            $t->boolean('is_active')->default(true);
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('role');
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->boolean('is_active')->default(true);
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
            $t->boolean('is_current')->default(false);
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); $t->unsignedSmallInteger('position')->default(1);
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id');
            $t->string('name'); $t->unsignedBigInteger('homeroom_teacher_id')->nullable();
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->string('name');
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id');
            $t->string('status')->default('active');
        });
        Schema::create('attendance_sessions', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id');
            $t->unsignedBigInteger('subject_id')->nullable(); $t->unsignedBigInteger('teacher_id')->nullable();
            $t->date('attendance_date'); $t->unsignedTinyInteger('period_number')->nullable();
            $t->string('status')->default('open'); $t->text('notes')->nullable(); $t->timestamps();
        });
        Schema::create('attendance_records', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('attendance_session_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->text('note')->nullable();
            $t->unsignedBigInteger('marked_by')->nullable(); $t->timestamp('marked_at')->nullable();
            $t->timestamps();
        });
        Schema::create('jabalia_attendance_change_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('attendance_session_id'); $t->unsignedBigInteger('child_id');
            $t->string('previous_status')->nullable(); $t->string('new_status');
            $t->unsignedBigInteger('actor_id')->nullable(); $t->timestamp('created_at');
        });
        Schema::create('jabalia_school_closure_days', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->date('closed_on');
        });
        Schema::create('child_parent', function (Blueprint $t) {
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id');
        });
        Schema::create('notifications', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id'); $t->string('title')->nullable();
            $t->string('message'); $t->string('type')->nullable(); $t->boolean('is_read')->default(false);
            $t->timestamp('created_at')->nullable();
        });
        DB::table('organizations')->insert([
            ['id'=>1,'slug'=>'jabalia','is_active'=>true],
            ['id'=>2,'slug'=>'other','is_active'=>true],
        ]);
        DB::table('schools')->insert([
            ['id'=>10,'organization_id'=>1,'name'=>'First','is_active'=>true],
            ['id'=>11,'organization_id'=>1,'name'=>'Second','is_active'=>true],
            ['id'=>12,'organization_id'=>2,'name'=>'Other','is_active'=>true],
            ['id'=>13,'organization_id'=>1,'name'=>'Inactive','is_active'=>false],
        ]);
        DB::table('users')->insert([
            ['id'=>101,'name'=>'Homeroom A','role'=>'teacher'],
            ['id'=>102,'name'=>'Homeroom B','role'=>'teacher'],
            ['id'=>103,'name'=>'Parent','role'=>'parent'],
            ['id'=>104,'name'=>'Institution','role'=>'institution'],
        ]);
        DB::table('organization_user')->insert([
            ['organization_id'=>1,'user_id'=>101,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>1,'user_id'=>102,'role'=>'teacher','is_active'=>true],
            ['organization_id'=>1,'user_id'=>104,'role'=>'owner','is_active'=>true],
        ]);
        DB::table('academic_years')->insert([
            ['id'=>1,'school_id'=>10,'is_current'=>true],
            ['id'=>2,'school_id'=>11,'is_current'=>true],
            ['id'=>3,'school_id'=>12,'is_current'=>true],
            ['id'=>4,'school_id'=>10,'is_current'=>false],
            ['id'=>5,'school_id'=>13,'is_current'=>true],
        ]);
        DB::table('grades')->insert([
            ['id'=>1,'school_id'=>10,'name'=>'A','position'=>1],
            ['id'=>2,'school_id'=>11,'name'=>'B','position'=>1],
            ['id'=>3,'school_id'=>12,'name'=>'C','position'=>1],
            ['id'=>4,'school_id'=>13,'name'=>'D','position'=>1],
        ]);
        DB::table('sections')->insert([
            ['id'=>21,'grade_id'=>1,'academic_year_id'=>1,'name'=>'A','homeroom_teacher_id'=>101],
            ['id'=>22,'grade_id'=>1,'academic_year_id'=>1,'name'=>'B','homeroom_teacher_id'=>102],
            ['id'=>23,'grade_id'=>2,'academic_year_id'=>2,'name'=>'C','homeroom_teacher_id'=>101],
            ['id'=>24,'grade_id'=>3,'academic_year_id'=>3,'name'=>'D','homeroom_teacher_id'=>101],
            ['id'=>25,'grade_id'=>1,'academic_year_id'=>4,'name'=>'Old','homeroom_teacher_id'=>101],
            ['id'=>26,'grade_id'=>1,'academic_year_id'=>1,'name'=>'Unassigned','homeroom_teacher_id'=>null],
            ['id'=>27,'grade_id'=>4,'academic_year_id'=>5,'name'=>'Inactive','homeroom_teacher_id'=>101],
        ]);
        DB::table('children')->insert([
            ['id'=>1,'organization_id'=>1,'name'=>'Child A'],
            ['id'=>2,'organization_id'=>1,'name'=>'Child B'],
            ['id'=>3,'organization_id'=>1,'name'=>'Child C'],
            ['id'=>4,'organization_id'=>2,'name'=>'Child D'],
        ]);
        DB::table('student_enrollments')->insert([
            ['child_id'=>1,'section_id'=>21,'status'=>'active'],
            ['child_id'=>2,'section_id'=>22,'status'=>'active'],
            ['child_id'=>3,'section_id'=>23,'status'=>'active'],
            ['child_id'=>4,'section_id'=>24,'status'=>'active'],
        ]);
        DB::table('child_parent')->insert(['child_id'=>1,'parent_id'=>103]);
    }

    protected function tearDown(): void
    {
        foreach (['notifications','child_parent','jabalia_school_closure_days',
            'jabalia_attendance_change_events','attendance_records','attendance_sessions',
            'student_enrollments','children','sections','grades','academic_years',
            'organization_user','users','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function request(array $payload = [], int $user = 101, string $role = 'teacher',
        int $organization = 1, string $slug = 'jabalia'): Request
    {
        $r = Request::create('/', 'POST', $payload);
        $r->attributes->set('jwt_user', (object) ['id'=>$user,'role'=>$role]);
        $r->attributes->set('organization', (object) ['id'=>$organization,'slug'=>$slug]);
        return $r;
    }

    private function today(): string
    {
        return now('Asia/Hebron')->toDateString();
    }

    private function begin(int $section = 21): int
    {
        $response = app(JabaliaHomeroomAttendanceController::class)
            ->start($this->request(['date'=>$this->today(), 'teacher_id'=>102, 'period_number'=>3]), 'jabalia', $section);
        $this->assertSame(201, $response->status());
        return (int) $response->getData(true)['attendance_session']['id'];
    }

    public function test_active_homeroom_teacher_sees_only_own_current_sections_across_own_schools(): void
    {
        $controller = app(JabaliaHomeroomAttendanceController::class);
        $result = $controller->sections($this->request(), 'jabalia')->getData(true);
        $this->assertSame([21, 23], array_column($result['sections'], 'section_id'));
        $this->assertSame($this->today(), $result['today']);
        $this->assertSame([22], array_column(
            $controller->sections($this->request([],102), 'jabalia')->getData(true)['sections'], 'section_id'
        ));
    }

    public function test_creates_only_today_daily_session_and_marks_own_children_without_closure_or_impersonation(): void
    {
        $controller = app(JabaliaHomeroomAttendanceController::class);
        $session = $this->begin();
        $row = DB::table('attendance_sessions')->find($session);
        $this->assertSame(21, (int) $row->section_id);
        $this->assertNull($row->period_number);
        $this->assertSame(101, (int) $row->teacher_id);
        $this->assertSame('present', DB::table('attendance_records')->value('status'));
        $this->assertNull(DB::table('attendance_records')->value('marked_at'));

        $show = $controller->show($this->request(['date'=>$this->today()]), 'jabalia', 21)->getData(true);
        $this->assertSame(1, $show['records'][0]['child_id']);
        $this->assertFalse($show['records'][0]['confirmed']);
        $this->assertCount(1, $show['records']);
        $this->assertTrue($show['can_mark']);

        DB::table('attendance_records')->where('attendance_session_id',$session)
            ->update(['note'=>'private administration note']);
        $saved = $controller->mark($this->request([
            'records'=>[['child_id'=>1,'status'=>'present']],
            'close_session'=>true, 'note'=>'not permitted',
        ]), 'jabalia', 21, $session);
        $this->assertSame(200, $saved->status());
        $this->assertSame('open', DB::table('attendance_sessions')->value('status'));
        $this->assertNotNull(DB::table('attendance_records')->value('marked_at'));
        $this->assertSame(101, (int) DB::table('attendance_records')->value('marked_by'));
        $this->assertSame(0, DB::table('jabalia_attendance_change_events')->count());
        $this->assertSame('private administration note', DB::table('attendance_records')->value('note'));
        $this->assertArrayNotHasKey('note', $controller->show(
            $this->request(), 'jabalia', 21
        )->getData(true)['records'][0]);
        $this->assertTrue($controller->show($this->request(), 'jabalia', 21)->getData(true)['records'][0]['confirmed']);
        $this->assertSame(409, $controller->start(
            $this->request(['date'=>$this->today()]), 'jabalia', 21
        )->status());
    }

    public function test_foreign_legacy_unassigned_and_inactive_sections_fail_closed(): void
    {
        $controller = app(JabaliaHomeroomAttendanceController::class);
        foreach ([22,24,25,26,27,999] as $section) {
            $this->assertSame(404, $controller->show($this->request(), 'jabalia', $section)->status());
            $this->assertSame(404, $controller->start($this->request([
                'date'=>$this->today(),
            ]), 'jabalia', $section)->status());
        }
        $this->assertSame(404, $controller->sections($this->request([],103,'parent'), 'jabalia')->status());
        $this->assertSame(404, $controller->sections($this->request([],104,'institution'), 'jabalia')->status());
        $this->assertSame(404, $controller->sections($this->request([],101,'teacher',2,'other'), 'other')->status());
        DB::table('organization_user')->where('user_id',101)->update(['is_active'=>false]);
        $this->assertSame(404, $controller->sections($this->request(), 'jabalia')->status());
        $this->assertSame(0, DB::table('attendance_sessions')->count());
    }

    public function test_cannot_mark_another_sections_session_or_lecture_or_yesterday(): void
    {
        $controller = app(JabaliaHomeroomAttendanceController::class);
        $id = $this->begin();
        $foreign = DB::table('attendance_sessions')->insertGetId([
            'section_id'=>22,'attendance_date'=>$this->today(),'period_number'=>null,
            'status'=>'open','created_at'=>now(),'updated_at'=>now(),
        ]);
        $lecture = DB::table('attendance_sessions')->insertGetId([
            'section_id'=>21,'attendance_date'=>$this->today(),'period_number'=>2,
            'status'=>'open','created_at'=>now(),'updated_at'=>now(),
        ]);
        $yesterday = DB::table('attendance_sessions')->insertGetId([
            'section_id'=>21,'attendance_date'=>now('Asia/Hebron')->subDay()->toDateString(),
            'period_number'=>null,'status'=>'open','created_at'=>now(),'updated_at'=>now(),
        ]);
        $records = ['records'=>[['child_id'=>1,'status'=>'absent']]];
        foreach ([$foreign,$lecture,$yesterday] as $session) {
            $this->assertSame(404, $controller->mark(
                $this->request($records),'jabalia',21,$session
            )->status());
        }
        $this->assertSame(404, $controller->mark(
            $this->request($records,102),'jabalia',21,$id
        )->status());
        $this->assertSame(422, $controller->mark($this->request([
            'records'=>[['child_id'=>2,'status'=>'absent']],
        ]),'jabalia',21,$id)->status());
        $this->assertSame(0, DB::table('jabalia_attendance_change_events')->count());
    }

    public function test_homeroom_reassignment_and_closed_session_reject_writes(): void
    {
        $controller = app(JabaliaHomeroomAttendanceController::class);
        $id = $this->begin();
        DB::table('sections')->where('id',21)->update(['homeroom_teacher_id'=>102]);
        $this->assertSame(404, $controller->mark($this->request([
            'records'=>[['child_id'=>1,'status'=>'absent']],
        ]),'jabalia',21,$id)->status());
        DB::table('sections')->where('id',21)->update(['homeroom_teacher_id'=>101]);
        DB::table('attendance_sessions')->where('id',$id)->update(['status'=>'closed']);
        $this->assertSame(409, $controller->mark($this->request([
            'records'=>[['child_id'=>1,'status'=>'absent']],
        ]),'jabalia',21,$id)->status());
    }

    public function test_daily_teacher_cannot_create_backdated_or_future_roll(): void
    {
        $controller = app(JabaliaHomeroomAttendanceController::class);
        foreach ([-1,1] as $shift) {
            $this->assertSame(422, $controller->start($this->request([
                'date'=>now('Asia/Hebron')->addDays($shift)->toDateString(),
                'teacher_id'=>9999, 'period_number'=>2,
            ]), 'jabalia',21)->status());
        }
        $this->assertSame(0, DB::table('attendance_sessions')->count());
    }

    public function test_anonymous_route_cannot_list_homeroom_sections(): void
    {
        $response = $this->getJson('/api/institutions/jabalia/homeroom/sections');
        $this->assertContains($response->status(), [401,403]);
    }
}
