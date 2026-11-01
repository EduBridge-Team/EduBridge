<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaTeacherSchoolTransferController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaTeacherTransferGuardsTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) { $t->id(); $t->string('slug'); });
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); });
        Schema::create('users', function (Blueprint $t) { $t->id(); });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->boolean('is_active');
        });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); });
        Schema::create('subjects', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); });
        Schema::create('teacher_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id'); $t->unsignedBigInteger('teacher_id');
        });
        Schema::create('timetable_entries', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('section_id');
            $t->unsignedBigInteger('subject_id'); $t->unsignedBigInteger('teacher_id');
        });
        Schema::create('jabalia_teacher_assignment_history', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('teacher_id'); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id');
            $t->date('starts_on'); $t->date('ends_on')->nullable(); $t->string('status');
            $t->string('reason')->nullable(); $t->unsignedBigInteger('recorded_by')->nullable(); $t->timestamps();
        });
        Schema::create('jabalia_teacher_school_transfers', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('teacher_id');
            $t->unsignedBigInteger('from_school_id'); $t->unsignedBigInteger('to_school_id');
            $t->date('effective_on'); $t->string('reason')->nullable();
            $t->unsignedBigInteger('recorded_by')->nullable(); $t->timestamps();
        });
        DB::table('organizations')->insert(['id'=>1,'slug'=>'jabalia']);
        DB::table('schools')->insert([['id'=>1,'organization_id'=>1],['id'=>2,'organization_id'=>1]]);
        DB::table('users')->insert(['id'=>10]);
        DB::table('organization_user')->insert(['organization_id'=>1,'user_id'=>10,'role'=>'teacher','is_active'=>true]);
        DB::table('grades')->insert(['id'=>1,'school_id'=>1]);
        DB::table('sections')->insert(['id'=>1,'grade_id'=>1]);
        DB::table('subjects')->insert(['id'=>1,'school_id'=>1]);
        DB::table('teacher_assignments')->insert(['id'=>1,'section_id'=>1,'subject_id'=>1,'teacher_id'=>10]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_teacher_school_transfers','jabalia_teacher_assignment_history','timetable_entries',
            'teacher_assignments','subjects','sections','grades','organization_user','users','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function transfer(): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/', 'POST', [
            'to_school_id'=>2, 'effective_on'=>'2026-10-30',
        ]);
        $request->attributes->set('organization', (object)['id'=>1,'slug'=>'jabalia']);
        $request->attributes->set('jwt_user', (object)['id'=>99]);
        return app(JabaliaTeacherSchoolTransferController::class)->store($request,'jabalia',1,10);
    }

    public function test_transfer_preserves_assignments_if_teacher_has_lessons(): void
    {
        DB::table('timetable_entries')->insert(['school_id'=>1,'section_id'=>1,'subject_id'=>1,'teacher_id'=>10]);
        $this->assertSame(409,$this->transfer()->getStatusCode());
        $this->assertSame(1,DB::table('teacher_assignments')->count());
        $this->assertSame(0,DB::table('jabalia_teacher_school_transfers')->count());
    }

    public function test_orphaned_timetable_lesson_blocks_transfer_even_without_active_assignment(): void
    {
        DB::table('teacher_assignments')->delete();
        DB::table('timetable_entries')->insert([
            'school_id'=>1, 'section_id'=>1, 'subject_id'=>1, 'teacher_id'=>10,
        ]);

        $this->assertSame(409, $this->transfer()->getStatusCode());
        $this->assertSame(1, DB::table('timetable_entries')->count());
        $this->assertSame(0, DB::table('jabalia_teacher_school_transfers')->count());

        DB::table('timetable_entries')->delete();
        $this->assertSame(201, $this->transfer()->getStatusCode());
        $this->assertSame(1, DB::table('jabalia_teacher_school_transfers')->count());
    }

    public function test_transfer_closes_assignments_after_lessons_are_removed(): void
    {
        $this->assertSame(201,$this->transfer()->getStatusCode());
        $this->assertSame(0,DB::table('teacher_assignments')->count());
        $this->assertSame(1,DB::table('jabalia_teacher_school_transfers')->count());
        $this->assertSame(409,$this->transfer()->getStatusCode());
    }
}
