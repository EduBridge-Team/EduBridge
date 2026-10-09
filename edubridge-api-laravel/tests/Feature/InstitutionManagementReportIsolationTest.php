<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionManagementReportController;
use App\Http\Controllers\InstitutionAttendanceController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionManagementReportIsolationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); $t->string('name'); });
        Schema::create('organization_user', function (Blueprint $t) { $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id'); $t->string('role'); $t->boolean('is_active'); });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); $t->string('name'); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); });
        Schema::create('student_enrollments', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('child_id'); $t->string('status'); });
        Schema::create('timetable_entries', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); });
        Schema::create('attendance_sessions', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('section_id'); $t->date('attendance_date'); $t->unsignedBigInteger('subject_id')->nullable(); $t->unsignedBigInteger('teacher_id')->nullable(); $t->unsignedInteger('period_number')->nullable(); $t->string('status')->default('open'); $t->text('notes')->nullable(); $t->timestamps(); });
        Schema::create('attendance_records', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('attendance_session_id'); $t->unsignedBigInteger('child_id'); $t->string('status'); $t->text('note')->nullable(); $t->unsignedBigInteger('marked_by')->nullable(); $t->dateTime('marked_at')->nullable(); $t->timestamps(); });
        Schema::create('child_parent', function (Blueprint $t) { $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id'); });
        Schema::create('notifications', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('user_id'); $t->string('title'); $t->text('message'); $t->string('type'); $t->boolean('is_read'); $t->timestamp('created_at')->nullable(); });

        DB::table('schools')->insert([['id' => 1, 'organization_id' => 1, 'name' => 'School A'], ['id' => 2, 'organization_id' => 2, 'name' => 'School B']]);
        DB::table('organization_user')->insert([['organization_id' => 1, 'user_id' => 1, 'role' => 'teacher', 'is_active' => true], ['organization_id' => 2, 'user_id' => 2, 'role' => 'teacher', 'is_active' => true]]);
        DB::table('children')->insert([['id' => 1, 'organization_id' => 1, 'name' => 'Child A'], ['id' => 2, 'organization_id' => 2, 'name' => 'Child B']]);
        DB::table('grades')->insert([['id' => 1, 'school_id' => 1], ['id' => 2, 'school_id' => 2]]);
        DB::table('sections')->insert([['id' => 1, 'grade_id' => 1], ['id' => 2, 'grade_id' => 2]]);
        DB::table('student_enrollments')->insert([['id' => 1, 'section_id' => 1, 'child_id' => 1, 'status' => 'active'], ['id' => 2, 'section_id' => 2, 'child_id' => 2, 'status' => 'active']]);
        DB::table('timetable_entries')->insert([['id' => 1, 'school_id' => 1], ['id' => 2, 'school_id' => 2]]);
        DB::table('attendance_sessions')->insert([
            ['id' => 1, 'section_id' => 1, 'attendance_date' => '2026-10-01'],
            ['id' => 2, 'section_id' => 1, 'attendance_date' => '2026-10-09'],
            ['id' => 3, 'section_id' => 2, 'attendance_date' => '2026-10-09'],
        ]);
        DB::table('attendance_records')->insert([
            ['id' => 1, 'attendance_session_id' => 1, 'child_id' => 1, 'status' => 'absent'],
            ['id' => 2, 'attendance_session_id' => 2, 'child_id' => 1, 'status' => 'present'],
            ['id' => 3, 'attendance_session_id' => 3, 'child_id' => 2, 'status' => 'absent'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['notifications', 'child_parent', 'attendance_records', 'attendance_sessions', 'timetable_entries', 'student_enrollments', 'sections', 'grades', 'children', 'organization_user', 'schools'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function report(array $filters = []): array
    {
        $request = Request::create('/management-report', 'GET', $filters);
        $request->attributes->set('organization', (object) ['id' => 1]);
        return app(InstitutionManagementReportController::class)->index($request, 'school-a')->getData(true);
    }

    public function test_report_only_contains_own_institution(): void
    {
        $data = $this->report();
        $this->assertSame(1, $data['summary']['schools']);
        $this->assertSame(1, $data['summary']['active_teachers']);
        $this->assertSame(1, $data['summary']['student_files']);
        $this->assertSame(1, $data['summary']['active_enrollments']);
        $this->assertCount(1, $data['schools']);
        $this->assertSame('School A', $data['schools'][0]['school_name']);
        $this->assertSame(2, $data['schools'][0]['attendance_sessions']);
        $this->assertSame(1, $data['schools'][0]['attendance']['absent']);
    }

    public function test_date_filter_only_changes_attendance_metrics(): void
    {
        $data = $this->report(['from' => '2026-10-09', 'to' => '2026-10-09']);
        $this->assertSame(1, $data['schools'][0]['attendance_sessions']);
        $this->assertSame(1, $data['schools'][0]['attendance']['present']);
        $this->assertSame(0, $data['schools'][0]['attendance']['absent']);
        $this->assertSame(1, $data['summary']['active_enrollments']);
        $this->assertSame(1, $data['schools'][0]['timetable_entries']);
    }
}
