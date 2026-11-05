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
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id')->nullable(); $t->string('name'); });
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
        Schema::create('jabalia_attendance_change_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('attendance_session_id'); $t->unsignedBigInteger('child_id');
            $t->string('previous_status')->nullable(); $t->string('new_status');
            $t->unsignedBigInteger('actor_id')->nullable(); $t->timestamp('created_at');
        });
        Schema::create('jabalia_school_closure_days', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id'); $t->date('closed_on');
            $t->string('reason'); $t->timestamps();
        });
        Schema::create('teacher_assignments', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id'); $t->unsignedBigInteger('teacher_id'); });
        Schema::create('timetable_entries', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('academic_year_id'); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id'); $t->unsignedBigInteger('teacher_id')->nullable(); $t->unsignedTinyInteger('weekday'); $t->unsignedTinyInteger('period_number'); $t->time('starts_at')->nullable(); $t->time('ends_at')->nullable(); $t->string('room')->nullable(); $t->timestamps(); });

        DB::table('organizations')->insert(['id' => 1, 'slug' => 'jabalia', 'is_active' => true]);
        DB::table('users')->insert([['id' => 10, 'name' => 'Teacher'], ['id' => 20, 'name' => 'Parent'], ['id' => 30, 'name' => 'Admin']]);
        DB::table('organization_user')->insert(['organization_id' => 1, 'user_id' => 10, 'role' => 'teacher', 'is_active' => true]);
        DB::table('schools')->insert(['id' => 1, 'organization_id' => 1, 'name' => 'School']);
        DB::table('academic_years')->insert(['id' => 1, 'school_id' => 1, 'name' => '2026/2027']);
        DB::table('grades')->insert(['id' => 1, 'school_id' => 1, 'name' => 'Grade 4']);
        DB::table('sections')->insert([['id' => 1, 'grade_id' => 1, 'academic_year_id' => 1, 'name' => 'A'], ['id' => 2, 'grade_id' => 1, 'academic_year_id' => 1, 'name' => 'B']]);
        DB::table('subjects')->insert(['id' => 1, 'school_id' => 1, 'name' => 'Science']);
        DB::table('teacher_assignments')->insert([['section_id'=>1, 'subject_id'=>1, 'teacher_id'=>10], ['section_id'=>2, 'subject_id'=>1, 'teacher_id'=>10]]);
        DB::table('children')->insert(['id' => 1, 'name' => 'Student', 'organization_id' => 1]);
        DB::table('student_enrollments')->insert(['child_id' => 1, 'section_id' => 1, 'status' => 'active']);
        DB::table('child_parent')->insert(['child_id' => 1, 'parent_id' => 20]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_attendance_change_events','jabalia_school_closure_days','teacher_assignments','timetable_entries','attendance_records','attendance_sessions','notifications','child_parent','student_enrollments','children','subjects','sections','grades','academic_years','schools','organization_user','users','organizations'] as $table) {
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

    public function test_teacher_assignment_is_checked_after_organization_lock(): void
    {
        // Emulate the state after a completed transfer removed the assignment.
        // The timetable writer must reject it rather than create a stale lesson.
        DB::table('teacher_assignments')->where('teacher_id', 10)->delete();

        $response = app(InstitutionTimetableController::class)->store(
            $this->tenantRequest([
                'academic_year_id'=>1, 'section_id'=>1, 'subject_id'=>1,
                'teacher_id'=>10, 'weekday'=>1, 'period_number'=>2,
            ]), 'jabalia', 1
        );

        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame(0, DB::table('timetable_entries')->count());
    }

    public function test_teacher_without_matching_assignment_cannot_be_scheduled(): void
    {
        DB::table('teacher_assignments')->where('section_id', 2)->delete();
        $response = app(InstitutionTimetableController::class)->store(
            $this->tenantRequest(['academic_year_id'=>1,'section_id'=>2,'subject_id'=>1,
                'teacher_id'=>10,'weekday'=>1,'period_number'=>2]), 'jabalia', 1);
        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame(0, DB::table('timetable_entries')->count());
    }

    public function test_jabalia_notifies_only_on_fourth_consecutive_school_day(): void
    {
        $controller = app(InstitutionAttendanceController::class);
        foreach (['2026-10-04','2026-10-05','2026-10-06','2026-10-07'] as $index => $date) {
            $sessionId = DB::table('attendance_sessions')->insertGetId([
                'section_id'=>1,'attendance_date'=>$date,'period_number'=>null,'status'=>'open',
                'created_at'=>now(),'updated_at'=>now(),
            ]);
            DB::table('attendance_records')->insert([
                'attendance_session_id'=>$sessionId,'child_id'=>1,'status'=>'present',
                'created_at'=>now(),'updated_at'=>now(),
            ]);
            $request = $this->tenantRequest(['records'=>[['child_id'=>1,'status'=>'absent']]]);
            $this->assertSame(200, $controller->mark($request,'jabalia',1,$sessionId)->getStatusCode());
            $this->assertSame($index === 3 ? 1 : 0, DB::table('notifications')
                ->where('type','school_attendance_consecutive')->count());
            $this->assertSame(0, DB::table('notifications')->where('type','school_attendance')->count());
        }
        $lastSession = DB::table('attendance_sessions')->where('attendance_date','2026-10-07')->value('id');
        $this->assertSame(200, $controller->mark($this->tenantRequest([
            'records'=>[['child_id'=>1,'status'=>'absent']],
        ]),'jabalia',1,$lastSession)->getStatusCode());
        $this->assertSame(1, DB::table('notifications')->where('type','school_attendance_consecutive')->count());
    }

    public function test_recorded_school_closure_does_not_break_four_open_day_absence_streak(): void
    {
        // The association's Tuesday closure is configured, not inferred.
        DB::table('jabalia_school_closure_days')->insert([
            'organization_id' => 1, 'school_id' => 1,
            'closed_on' => '2026-10-06', 'reason' => 'Confirmed closure',
        ]);
        $controller = app(InstitutionAttendanceController::class);
        foreach (['2026-10-04', '2026-10-05', '2026-10-07', '2026-10-08'] as $index => $date) {
            $sessionId = DB::table('attendance_sessions')->insertGetId([
                'section_id' => 1, 'attendance_date' => $date,
                'period_number' => null, 'status' => 'open',
                'created_at' => now(), 'updated_at' => now(),
            ]);
            DB::table('attendance_records')->insert([
                'attendance_session_id' => $sessionId, 'child_id' => 1,
                'status' => 'present', 'created_at' => now(), 'updated_at' => now(),
            ]);
            $this->assertSame(200, $controller->mark($this->tenantRequest([
                'records' => [['child_id' => 1, 'status' => 'absent']],
            ]), 'jabalia', 1, $sessionId)->status());
            $this->assertSame($index === 3 ? 1 : 0,
                DB::table('notifications')->where('type', 'school_attendance_consecutive')->count());
        }
    }

    public function test_closed_day_rejects_attendance_session_without_adding_child_records(): void
    {
        DB::table('jabalia_school_closure_days')->insert([
            'organization_id' => 1, 'school_id' => 1,
            'closed_on' => '2026-11-12', 'reason' => 'Approved closure',
        ]);
        $response = app(InstitutionAttendanceController::class)->store(
            $this->tenantRequest([
                'section_id' => 1, 'attendance_date' => '2026-11-12',
            ]), 'jabalia', 1
        );
        $this->assertSame(409, $response->status());
        $this->assertSame(0, DB::table('attendance_sessions')->count());
        $this->assertSame(0, DB::table('attendance_records')->count());
    }

    public function test_missing_daily_roll_breaks_absence_streak(): void
    {
        $controller = app(InstitutionAttendanceController::class);
        foreach (['2026-10-04','2026-10-05','2026-10-07','2026-10-08'] as $date) {
            $sessionId = DB::table('attendance_sessions')->insertGetId([
                'section_id'=>1,'attendance_date'=>$date,'period_number'=>null,'status'=>'open',
                'created_at'=>now(),'updated_at'=>now(),
            ]);
            DB::table('attendance_records')->insert([
                'attendance_session_id'=>$sessionId,'child_id'=>1,'status'=>'present',
                'created_at'=>now(),'updated_at'=>now(),
            ]);
            $this->assertSame(200, $controller->mark($this->tenantRequest([
                'records'=>[['child_id'=>1,'status'=>'absent']],
            ]),'jabalia',1,$sessionId)->getStatusCode());
        }
        $this->assertSame(0, DB::table('notifications')->where('type','school_attendance_consecutive')->count());
    }


    public function test_teacher_cannot_be_booked_in_two_jabalia_schools_same_period(): void
    {
        DB::table('schools')->insert(['id'=>2,'organization_id'=>1,'name'=>'Second school']);
        DB::table('academic_years')->insert(['id'=>2,'school_id'=>2,'name'=>'2026/2027']);
        DB::table('grades')->insert(['id'=>2,'school_id'=>2,'name'=>'Grade 5']);
        DB::table('sections')->insert(['id'=>3,'grade_id'=>2,'academic_year_id'=>2,'name'=>'C']);
        DB::table('subjects')->insert(['id'=>2,'school_id'=>2,'name'=>'Science']);
        DB::table('teacher_assignments')->insert(['section_id'=>3,'subject_id'=>2,'teacher_id'=>10]);

        $controller = app(InstitutionTimetableController::class);
        $first = $controller->store($this->tenantRequest([
            'academic_year_id'=>1,'section_id'=>1,'subject_id'=>1,
            'teacher_id'=>10,'weekday'=>1,'period_number'=>2,
        ]), 'jabalia', 1);
        $this->assertSame(201, $first->getStatusCode());

        $second = $controller->store($this->tenantRequest([
            'academic_year_id'=>2,'section_id'=>3,'subject_id'=>2,
            'teacher_id'=>10,'weekday'=>1,'period_number'=>2,
        ]), 'jabalia', 2);
        $this->assertSame(409, $second->getStatusCode());
        $this->assertSame(1, DB::table('timetable_entries')->count());
    }

    public function test_deleting_timetable_entry_allows_rebooking_the_same_slot(): void
    {
        $controller = app(InstitutionTimetableController::class);
        $payload = ['academic_year_id'=>1,'section_id'=>1,'subject_id'=>1,
            'teacher_id'=>10,'weekday'=>1,'period_number'=>2];
        $this->assertSame(201, $controller->store($this->tenantRequest($payload), 'jabalia', 1)->getStatusCode());

        $entryId = DB::table('timetable_entries')->value('id');
        $this->assertSame(200, $controller->destroy($this->tenantRequest([]), 'jabalia', 1, $entryId)->getStatusCode());
        $this->assertSame(0, DB::table('timetable_entries')->count());
        $this->assertSame(201, $controller->store($this->tenantRequest($payload), 'jabalia', 1)->getStatusCode());
        $this->assertSame(1, DB::table('timetable_entries')->count());
    }

    public function test_timetable_delete_is_scoped_to_its_school_and_is_idempotently_not_found(): void
    {
        $controller = app(InstitutionTimetableController::class);
        $this->assertSame(201, $controller->store($this->tenantRequest([
            'academic_year_id'=>1,'section_id'=>1,'subject_id'=>1,
            'teacher_id'=>10,'weekday'=>1,'period_number'=>2,
        ]), 'jabalia', 1)->getStatusCode());

        $entryId = DB::table('timetable_entries')->value('id');
        DB::table('schools')->insert(['id'=>2,'organization_id'=>1,'name'=>'Other school']);
        $this->assertSame(404, $controller->destroy($this->tenantRequest([]), 'jabalia', 2, $entryId)->getStatusCode());
        $this->assertSame(1, DB::table('timetable_entries')->count());
        $this->assertSame(200, $controller->destroy($this->tenantRequest([]), 'jabalia', 1, $entryId)->getStatusCode());
        $this->assertSame(404, $controller->destroy($this->tenantRequest([]), 'jabalia', 1, $entryId)->getStatusCode());
    }

    public function test_timetable_delete_rejects_school_outside_organization(): void
    {
        $controller = app(InstitutionTimetableController::class);
        DB::table('organizations')->insert(['id'=>2,'slug'=>'other','is_active'=>true]);
        DB::table('schools')->insert(['id'=>3,'organization_id'=>2,'name'=>'Foreign school']);
        $this->assertSame(404, $controller->destroy($this->tenantRequest([]), 'jabalia', 3, 999)->getStatusCode());
    }

    public function test_non_jabalia_organization_rejects_teacher_booking_in_two_schools_same_slot(): void
    {
        DB::table('organizations')->insert(['id' => 2, 'slug' => 'demo', 'is_active' => true]);
        DB::table('organization_user')->insert(['organization_id' => 2, 'user_id' => 10, 'role' => 'teacher', 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 3, 'organization_id' => 2, 'name' => 'Demo A'],
            ['id' => 4, 'organization_id' => 2, 'name' => 'Demo B'],
        ]);
        DB::table('academic_years')->insert([
            ['id' => 3, 'school_id' => 3, 'name' => '2026/2027'],
            ['id' => 4, 'school_id' => 4, 'name' => '2026/2027'],
        ]);
        DB::table('grades')->insert([
            ['id' => 3, 'school_id' => 3, 'name' => 'Grade A'],
            ['id' => 4, 'school_id' => 4, 'name' => 'Grade B'],
        ]);
        DB::table('sections')->insert([
            ['id' => 3, 'grade_id' => 3, 'academic_year_id' => 3, 'name' => 'A'],
            ['id' => 4, 'grade_id' => 4, 'academic_year_id' => 4, 'name' => 'B'],
        ]);
        DB::table('subjects')->insert([
            ['id' => 3, 'school_id' => 3, 'name' => 'English'],
            ['id' => 4, 'school_id' => 4, 'name' => 'English'],
        ]);
        $request = fn (int $year, int $section, int $subject) =>
            tap(Request::create('/', 'POST', [
                'academic_year_id' => $year, 'section_id' => $section,
                'subject_id' => $subject, 'teacher_id' => 10,
                'weekday' => 1, 'period_number' => 2,
            ]), fn ($request) => $request->attributes->set('organization', (object) ['id' => 2, 'slug' => 'demo']));
        $controller = app(InstitutionTimetableController::class);
        $this->assertSame(201, $controller->store($request(3, 3, 3), 'demo', 3)->getStatusCode());
        $this->assertSame(409, $controller->store($request(4, 4, 4), 'demo', 4)->getStatusCode());
        $this->assertSame(1, DB::table('timetable_entries')->count());
    }

    public function test_independent_school_can_write_and_reject_duplicate_timetable_slot(): void
    {
        DB::table('schools')->insert(['id' => 5, 'organization_id' => null, 'name' => 'Independent']);
        DB::table('academic_years')->insert(['id' => 5, 'school_id' => 5, 'name' => '2026/2027']);
        DB::table('grades')->insert(['id' => 5, 'school_id' => 5, 'name' => 'Grade']);
        DB::table('sections')->insert(['id' => 5, 'grade_id' => 5, 'academic_year_id' => 5, 'name' => 'A']);
        DB::table('subjects')->insert(['id' => 5, 'school_id' => 5, 'name' => 'Arabic']);
        $request = fn () => tap(Request::create('/', 'POST', [
            'academic_year_id' => 5, 'section_id' => 5,
            'subject_id' => 5, 'weekday' => 1, 'period_number' => 2,
        ]), fn ($request) => $request->attributes->set('organization', (object) ['id' => null, 'slug' => null]));
        $controller = app(InstitutionTimetableController::class);
        $this->assertSame(201, $controller->store($request(), '', 5)->getStatusCode());
        $this->assertSame(409, $controller->store($request(), '', 5)->getStatusCode());
        $this->assertSame(1, DB::table('timetable_entries')->count());
    }

    public function test_only_fourth_not_fifth_or_sixth_school_absence_notifies_guardian(): void
    {
        $controller = app(InstitutionAttendanceController::class);
        foreach (['2026-10-04', '2026-10-05', '2026-10-06', '2026-10-07', '2026-10-08', '2026-10-11'] as $index => $date) {
            $id = DB::table('attendance_sessions')->insertGetId([
                'section_id'=>1, 'attendance_date'=>$date, 'period_number'=>null,
                'status'=>'open', 'created_at'=>now(), 'updated_at'=>now(),
            ]);
            DB::table('attendance_records')->insert([
                'attendance_session_id'=>$id, 'child_id'=>1, 'status'=>'present',
                'created_at'=>now(), 'updated_at'=>now(),
            ]);
            $this->assertSame(200, $controller->mark($this->tenantRequest([
                'records'=>[['child_id'=>1, 'status'=>'absent']],
            ]), 'jabalia', 1, $id)->status());
            $this->assertSame($index >= 3 ? 1 : 0,
                DB::table('notifications')->where('type','school_attendance_consecutive')->count(),
                "Unexpected notification on day index {$index}");
        }
        $this->assertSame(6, DB::table('jabalia_attendance_change_events')->count());
    }

    public function test_attendance_change_history_is_append_only_and_repeat_saves_are_idempotent(): void
    {
        $sessionId = DB::table('attendance_sessions')->insertGetId([
            'section_id'=>1,'attendance_date'=>'2026-10-07','period_number'=>null,
            'status'=>'open','created_at'=>now()->subDay(),'updated_at'=>now()->subDay(),
        ]);
        $created = now()->subDay();
        DB::table('attendance_records')->insert([
            'attendance_session_id'=>$sessionId, 'child_id'=>1,
            'status'=>'present', 'note'=>null, 'created_at'=>$created, 'updated_at'=>$created,
        ]);
        $controller = app(InstitutionAttendanceController::class);
        $save = fn ($status, $close = false) => $controller->mark(
            $this->tenantRequest(['records'=>[['child_id'=>1,'status'=>$status]],'close_session'=>$close]),
            'jabalia', 1, $sessionId
        );
        $this->assertSame(200, $save('absent')->status());
        $this->assertSame(200, $save('absent')->status());
        $this->assertSame(200, $save('present')->status());
        $this->assertSame(200, $save('present', true)->status());
        $this->assertSame(409, $save('absent')->status());
        $this->assertSame(2, DB::table('jabalia_attendance_change_events')->count());
        $history = DB::table('jabalia_attendance_change_events')->orderBy('id')->get();
        $this->assertSame(['present','absent'], $history->pluck('previous_status')->all());
        $this->assertSame(['absent','present'], $history->pluck('new_status')->all());
        $this->assertSame([30,30], $history->pluck('actor_id')->all());
        $this->assertSame((string) $created->toDateTimeString(),
            (string) \Carbon\Carbon::parse(DB::table('attendance_records')->value('created_at'))->toDateTimeString());
        $view = $this->tenantRequest([]);
        $view->attributes->set('jwt_user', (object)['id'=>30,'role'=>'institution']);
        $result = $controller->changeHistory($view, 'jabalia', 1, $sessionId)->getData(true);
        $this->assertCount(2, $result['events']['data']);
        $this->assertArrayNotHasKey('child_name', $result['events']['data'][0]);
        $this->assertArrayNotHasKey('note', $result['events']['data'][0]);
    }

    public function test_attendance_history_does_not_cross_schools_or_roles(): void
    {
        $sessionId = DB::table('attendance_sessions')->insertGetId([
            'section_id'=>1,'attendance_date'=>'2026-10-07','period_number'=>null,
            'status'=>'open','created_at'=>now(),'updated_at'=>now(),
        ]);
        DB::table('attendance_records')->insert([
            'attendance_session_id'=>$sessionId, 'child_id'=>1,
            'status'=>'present', 'created_at'=>now(),'updated_at'=>now(),
        ]);
        $controller = app(InstitutionAttendanceController::class);
        $this->assertSame(200, $controller->mark($this->tenantRequest([
            'records'=>[['child_id'=>1,'status'=>'absent']],
        ]), 'jabalia', 1, $sessionId)->status());
        $view = $this->tenantRequest([]);
        $view->attributes->set('jwt_user', (object)['id'=>30,'role'=>'institution']);
        $this->assertSame(404, $controller->changeHistory($view, 'jabalia', 2, $sessionId)->status());
        $view->attributes->set('jwt_user', (object)['id'=>20,'role'=>'parent']);
        $this->assertSame(404, $controller->changeHistory($view, 'jabalia', 1, $sessionId)->status());
        $view->attributes->set('organization', (object)['id'=>2,'slug'=>'other']);
        $this->assertSame(404, $controller->changeHistory($view, 'other', 1, $sessionId)->status());
    }

    public function test_daily_only_attendance_controls_streak_alerts(): void
    {
        $controller = app(InstitutionAttendanceController::class);
        foreach (['2026-10-04','2026-10-05','2026-10-06'] as $date) {
            $id = DB::table('attendance_sessions')->insertGetId([
                'section_id'=>1,'attendance_date'=>$date,'period_number'=>null,
                'status'=>'open','created_at'=>now(),'updated_at'=>now(),
            ]);
            DB::table('attendance_records')->insert([
                'attendance_session_id'=>$id,'child_id'=>1,'status'=>'present',
                'created_at'=>now(),'updated_at'=>now(),
            ]);
            $controller->mark($this->tenantRequest(['records'=>[['child_id'=>1,'status'=>'absent']]]),
                'jabalia', 1, $id);
        }
        $period = DB::table('attendance_sessions')->insertGetId([
            'section_id'=>1,'attendance_date'=>'2026-10-07','period_number'=>2,
            'status'=>'open','created_at'=>now(),'updated_at'=>now(),
        ]);
        DB::table('attendance_records')->insert([
            'attendance_session_id'=>$period,'child_id'=>1,'status'=>'present',
            'created_at'=>now(),'updated_at'=>now(),
        ]);
        $this->assertSame(200, $controller->mark($this->tenantRequest([
            'records'=>[['child_id'=>1,'status'=>'absent']],
        ]),'jabalia',1,$period)->status());
        $this->assertSame(0, DB::table('notifications')->where('type','school_attendance_consecutive')->count());
    }

    private function tenantRequest(array $payload): Request
    {
        $request = Request::create('/', 'POST', $payload);
        $request->attributes->set('organization', (object) ['id' => 1, 'slug' => 'jabalia']);
        $request->attributes->set('jwt_user', (object) ['id' => 30, 'role' => 'admin']);
        return $request;
    }
}
