<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionAttendanceController;
use App\Http\Controllers\InstitutionTimetableController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionTimetableAttendanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('organizations', function (Blueprint $t) { $t->id(); $t->string('slug'); $t->boolean('is_active')->default(true); });
        Schema::create('users', function (Blueprint $t) { $t->id(); $t->string('name'); });
        Schema::create('organization_user', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id'); $t->string('role'); $t->boolean('is_active')->default(true); });
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); $t->string('name'); });
        Schema::create('academic_years', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id'); $t->string('name'); });
        Schema::create('subjects', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id'); });
        Schema::create('student_enrollments', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id'); $t->string('status')->default('active'); });
        Schema::create('child_parent', function (Blueprint $t) { $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id'); });
        Schema::create('notifications', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('user_id'); $t->string('title')->nullable(); $t->string('message'); $t->string('type')->nullable(); $t->boolean('is_read')->default(false); $t->timestamp('created_at')->nullable(); });
        Schema::create('attendance_sessions', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id')->nullable(); $t->unsignedBigInteger('teacher_id')->nullable(); $t->date('attendance_date'); $t->unsignedTinyInteger('period_number')->nullable(); $t->string('status')->default('open'); $t->text('notes')->nullable(); $t->timestamps(); });
        Schema::create('attendance_records', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('attendance_session_id'); $t->unsignedBigInteger('child_id'); $t->string('status'); $t->text('note')->nullable(); $t->unsignedBigInteger('marked_by')->nullable(); $t->timestamp('marked_at')->nullable(); $t->timestamps(); });
        Schema::create('timetable_entries', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('academic_year_id'); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id'); $t->unsignedBigInteger('teacher_id')->nullable(); $t->unsignedTinyInteger('weekday'); $t->unsignedTinyInteger('period_number'); $t->time('starts_at')->nullable(); $t->time('ends_at')->nullable(); $t->string('room')->nullable(); $t->timestamps(); });

        DB::table('organizations')->insert(['id' => 1, 'slug' => 'jabalia', 'is_active' => true]);
        DB::table('users')->insert([['id' => 10, 'name' => 'Teacher'], ['id' => 20, 'name' => 'Parent'], ['id' => 30, 'name' => 'Admin']]);
        DB::table('organization_user')->insert(['organization_id' => 1, 'user_id' => 10, 'role' => 'teacher', 'is_active' => true]);
        DB::table('schools')->insert(['id' => 1, 'organization_id' => 1, 'name' => 'School']);
        DB::table('academic_years')->insert(['id' => 1, 'school_id' => 1, 'name' => '2026/2027']);
        DB::table('grades')->insert(['id' => 1, 'school_id' => 1, 'name' => 'Grade 4']);
        DB::table('sections')->insert([['id' => 1, 'grade_id' => 1, 'academic_year_id' => 1, 'name' => 'A'], ['id' => 2, 'grade_id' => 1, 'academic_year_id' => 1, 'name' => 'B']]);
        DB::table('subjects')->insert(['id' => 1, 'school_id' => 1, 'name' => 'Science']);
        DB::table('children')->insert(['id' => 1, 'name' => 'Student', 'organization_id' => 1]);
        DB::table('student_enrollments')->insert(['child_id' => 1, 'section_id' => 1, 'status' => 'active']);
        DB::table('child_parent')->insert(['child_id' => 1, 'parent_id' => 20]);
    }

    protected function tearDown(): void
    {
        foreach (['timetable_entries','attendance_records','attendance_sessions','notifications','child_parent','student_enrollments','children','subjects','sections','grades','academic_years','schools','organization_user','users','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    public function test_teacher_conflict_is_rejected(): void
    {
        $controller = app(InstitutionTimetableController::class);
        $first = $controller->store($this->tenantRequest(['academic_year_id'=>1,'section_id'=>1,'subject_id'=>1,'teacher_id'=>10,'weekday'=>1,'period_number'=>2]), 'jabalia', 1);
        $this->assertSame(201, $first->getStatusCode());

        $second = $controller->store($this->tenantRequest(['academic_year_id'=>1,'section_id'=>2,'subject_id'=>1,'teacher_id'=>10,'weekday'=>1,'period_number'=>2]), 'jabalia', 1);
        $this->assertSame(409, $second->getStatusCode());
    }

    public function test_absence_creates_parent_notification_once(): void
    {
        $sessionId = DB::table('attendance_sessions')->insertGetId(['section_id'=>1,'subject_id'=>1,'teacher_id'=>10,'attendance_date'=>'2026-10-08','period_number'=>1,'status'=>'open','created_at'=>now(),'updated_at'=>now()]);
        DB::table('attendance_records')->insert(['attendance_session_id'=>$sessionId,'child_id'=>1,'status'=>'present','created_at'=>now(),'updated_at'=>now()]);

        $controller = app(InstitutionAttendanceController::class);
        $request = $this->tenantRequest(['records'=>[['child_id'=>1,'status'=>'absent']]]);
        $this->assertSame(200, $controller->mark($request, 'jabalia', 1, $sessionId)->getStatusCode());
        $this->assertSame(1, DB::table('notifications')->where('user_id', 20)->where('type', 'school_attendance')->count());

        $this->assertSame(200, $controller->mark($this->tenantRequest(['records'=>[['child_id'=>1,'status'=>'absent']]]), 'jabalia', 1, $sessionId)->getStatusCode());
        $this->assertSame(1, DB::table('notifications')->where('user_id', 20)->where('type', 'school_attendance')->count());
    }

    private function tenantRequest(array $payload): Request
    {
        $request = Request::create('/', 'POST', $payload);
        $request->attributes->set('organization', (object) ['id' => 1, 'slug' => 'jabalia']);
        $request->attributes->set('jwt_user', (object) ['id' => 30, 'role' => 'admin']);
        return $request;
    }
}
