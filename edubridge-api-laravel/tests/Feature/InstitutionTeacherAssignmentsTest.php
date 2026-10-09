<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionAcademicController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionTeacherAssignmentsTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->string('name');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
        });
        Schema::create('subjects', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id');
        });
        Schema::create('teacher_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id'); $t->unsignedBigInteger('teacher_id');
        });

        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => 1, 'name' => 'Jabalia'],
            ['id' => 2, 'organization_id' => 2, 'name' => 'Other'],
        ]);
        DB::table('grades')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'First'],
            ['id' => 2, 'school_id' => 2, 'name' => 'First'],
        ]);
        DB::table('subjects')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'Arabic'],
            ['id' => 2, 'school_id' => 2, 'name' => 'Arabic'],
        ]);
        DB::table('sections')->insert([
            ['id' => 1, 'grade_id' => 1],
            ['id' => 2, 'grade_id' => 2],
        ]);
        DB::table('teacher_assignments')->insert([
            ['id' => 1, 'section_id' => 1, 'subject_id' => 1, 'teacher_id' => 1],
            ['id' => 2, 'section_id' => 2, 'subject_id' => 2, 'teacher_id' => 2],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['teacher_assignments', 'sections', 'subjects', 'grades', 'schools'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function request(): Request
    {
        $request = Request::create('/api/institutions/jabalia/schools/1/academic/teacher-assignments', 'DELETE');
        $request->attributes->set('organization', (object) ['id' => 1, 'slug' => 'jabalia']);
        return $request;
    }

    public function test_assignment_can_only_be_removed_from_its_school(): void
    {
        $controller = app(InstitutionAcademicController::class);
        $forbidden = $controller->removeTeacherAssignment($this->request(), 'jabalia', 1, 2);
        $this->assertSame(404, $forbidden->getStatusCode());
        $this->assertDatabaseHas('teacher_assignments', ['id' => 2]);

        $removed = $controller->removeTeacherAssignment($this->request(), 'jabalia', 1, 1);
        $this->assertSame(200, $removed->getStatusCode());
        $this->assertDatabaseMissing('teacher_assignments', ['id' => 1]);
        $this->assertDatabaseHas('teacher_assignments', ['id' => 2]);
    }
}
