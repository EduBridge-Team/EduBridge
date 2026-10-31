<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolAcademicController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolAcademicControllerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('organizations', function (Blueprint $t) { $t->id(); $t->boolean('is_active'); });
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable(); $t->boolean('is_active'); });
        Schema::create('school_accounts', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('user_id'); $t->unsignedBigInteger('school_id'); });
        Schema::create('academic_years', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); $t->date('starts_on'); $t->date('ends_on'); $t->boolean('is_current'); $t->timestamps(); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); $t->integer('position'); $t->boolean('is_active'); $t->timestamps(); });
        Schema::create('sections', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id'); $t->string('name'); $t->integer('capacity')->nullable(); $t->timestamps(); });
        DB::table('schools')->insert([
            ['id' => 1, 'name' => 'A', 'organization_id' => null, 'is_active' => true],
            ['id' => 2, 'name' => 'B', 'organization_id' => null, 'is_active' => true],
        ]);
        DB::table('school_accounts')->insert(['user_id' => 10, 'school_id' => 1]);
    }

    protected function tearDown(): void
    {
        foreach (['sections', 'grades', 'academic_years', 'school_accounts', 'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        Schema::dropIfExists('school_management_assignments');
        parent::tearDown();
    }

    private function callAction(string $action, array $body = [], int $user = 10, string $role = 'school'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/academic', $action === 'index' ? 'GET' : 'POST', $body);
        $request->attributes->set('jwt_user', (object) ['id' => $user, 'role' => $role]);
        return app(SchoolAcademicController::class)->{$action}($request);
    }

    public function test_school_scope_and_role_are_enforced(): void
    {
        $this->assertSame(403, $this->callAction('index', [], 11)->getStatusCode());
        $this->assertSame(403, $this->callAction('index', [], 10, 'teacher')->getStatusCode());
        $this->assertSame(422, $this->callAction('storeGrade', ['expected_school_id' => 2, 'name' => 'Grade 1'])->getStatusCode());
        $this->assertSame(0, DB::table('grades')->count());
    }

    public function test_year_grade_and_section_are_created_in_own_school(): void
    {
        $year = $this->callAction('storeYear', [
            'expected_school_id' => 1, 'name' => '2026/2027',
            'starts_on' => '2026-09-01', 'ends_on' => '2027-06-30', 'is_current' => true,
        ]);
        $this->assertSame(201, $year->getStatusCode());
        $grade = $this->callAction('storeGrade', ['expected_school_id' => 1, 'name' => 'Grade 1']);
        $this->assertSame(201, $grade->getStatusCode());
        $section = $this->callAction('storeSection', [
            'expected_school_id' => 1, 'name' => 'A', 'academic_year_id' => $year->getData(true)['item']['id'],
            'grade_id' => $grade->getData(true)['item']['id'], 'capacity' => 30,
        ]);
        $this->assertSame(201, $section->getStatusCode());
        $this->assertSame(1, $section->getData(true)['item']['school_id']);
        $this->assertCount(1, $this->callAction('index')->getData(true)['sections']);
        $this->assertSame(409, $this->callAction('storeGrade', ['expected_school_id' => 1, 'name' => 'Grade 1'])->getStatusCode());
    }

    public function test_foreign_year_or_grade_is_rejected(): void
    {
        DB::table('academic_years')->insert([
            'id' => 2, 'school_id' => 2, 'name' => '2026/2027',
            'starts_on' => '2026-09-01', 'ends_on' => '2027-06-30', 'is_current' => true,
        ]);
        DB::table('grades')->insert(['id' => 2, 'school_id' => 2, 'name' => 'Grade 2', 'position' => 1, 'is_active' => true]);
        $result = $this->callAction('storeSection', [
            'expected_school_id' => 1, 'name' => 'A', 'academic_year_id' => 2,
            'grade_id' => 2, 'capacity' => 30,
        ]);
        $this->assertSame(422, $result->getStatusCode());
        $this->assertSame(0, DB::table('sections')->count());
    }
    public function test_personal_director_access_is_revoked_with_assignment(): void
    {
        DB::table('school_management_assignments')->insert([
            'school_id' => 1, 'user_id' => 30, 'role' => 'director', 'ends_at' => null,
        ]);
        $this->assertSame(200, $this->callAction('index', [], 30, 'teacher')->getStatusCode());
        DB::table('school_management_assignments')->where('user_id', 30)->update(['ends_at' => now()]);
        $this->assertSame(403, $this->callAction('index', [], 30, 'teacher')->getStatusCode());
    }
}
