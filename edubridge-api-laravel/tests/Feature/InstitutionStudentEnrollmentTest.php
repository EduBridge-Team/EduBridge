<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionStudentEnrollmentController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionStudentEnrollmentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id'); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id'); $t->string('name'); });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->date('enrolled_on'); $t->date('left_on')->nullable(); $t->timestamps();
        });
        DB::table('schools')->insert([['id' => 1, 'organization_id' => 1], ['id' => 2, 'organization_id' => 2]]);
        DB::table('children')->insert(['id' => 1, 'name' => 'Student', 'organization_id' => 1]);
        DB::table('grades')->insert([['id' => 1, 'school_id' => 1, 'name' => 'Grade'], ['id' => 2, 'school_id' => 2, 'name' => 'Other']]);
        DB::table('sections')->insert([
            ['id' => 1, 'grade_id' => 1, 'academic_year_id' => 1, 'name' => 'A'],
            ['id' => 2, 'grade_id' => 1, 'academic_year_id' => 1, 'name' => 'B'],
            ['id' => 3, 'grade_id' => 2, 'academic_year_id' => 1, 'name' => 'Other'],
        ]);
        DB::table('student_enrollments')->insert([
            'id' => 1, 'section_id' => 1, 'child_id' => 1, 'status' => 'active',
            'enrolled_on' => now()->toDateString(), 'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['student_enrollments', 'sections', 'grades', 'children', 'schools'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function transfer(int $organization, int $target): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/student-enrollments/1/transfer', 'POST', ['section_id' => $target]);
        $request->attributes->set('organization', (object) ['id' => $organization]);
        return app(InstitutionStudentEnrollmentController::class)->transfer($request, 'demo', 1, 1);
    }

    public function test_transfer_preserves_history_and_rejects_repeat(): void
    {
        $this->assertSame(201, $this->transfer(1, 2)->getStatusCode());
        $this->assertDatabaseHas('student_enrollments', ['id' => 1, 'status' => 'transferred']);
        $this->assertDatabaseHas('student_enrollments', ['section_id' => 2, 'child_id' => 1, 'status' => 'active']);
        $this->assertSame(409, $this->transfer(1, 2)->getStatusCode());
    }

    public function test_transfer_rejects_cross_tenant_and_cross_school(): void
    {
        $this->assertSame(404, $this->transfer(2, 2)->getStatusCode());
        $this->assertSame(422, $this->transfer(1, 3)->getStatusCode());
        $this->assertSame(1, DB::table('student_enrollments')->count());
    }
}
