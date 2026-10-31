<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolEnrollmentOptionsController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolEnrollmentOptionsTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id'); $t->unsignedBigInteger('school_id');
            $t->string('role'); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable(); $t->boolean('is_active');
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id'); $t->unsignedBigInteger('school_id');
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name'); $t->boolean('is_current');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
            $t->boolean('is_active'); $t->integer('position');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id'); $t->string('name');
        });
        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => null, 'is_active' => true],
            ['id' => 2, 'organization_id' => null, 'is_active' => true],
        ]);
        DB::table('school_accounts')->insert(['school_id' => 1, 'user_id' => 10]);
        DB::table('grades')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'Grade 1', 'is_active' => true, 'position' => 1],
            ['id' => 2, 'school_id' => 2, 'name' => 'Grade 2', 'is_active' => true, 'position' => 1],
        ]);
        DB::table('academic_years')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => '2026/2027', 'is_current' => true],
            ['id' => 2, 'school_id' => 2, 'name' => '2026/2027', 'is_current' => true],
            ['id' => 3, 'school_id' => 1, 'name' => '2025/2026', 'is_current' => false],
        ]);
        DB::table('sections')->insert([
            ['id' => 1, 'grade_id' => 1, 'academic_year_id' => 1, 'name' => 'A'],
            ['id' => 2, 'grade_id' => 2, 'academic_year_id' => 2, 'name' => 'B'],
            ['id' => 3, 'grade_id' => 1, 'academic_year_id' => 3, 'name' => 'Old'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_management_assignments', 'sections','grades','academic_years','school_accounts','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function schoolOptions(int $id, string $role = 'school'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/enrollment-options', 'GET', ['school_id' => 2]);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        return app(SchoolEnrollmentOptionsController::class)->index($request);
    }

    public function test_options_only_include_own_active_year(): void
    {
        $data = $this->schoolOptions(10)->getData(true);
        $this->assertSame(1, $data['school_id']);
        $this->assertCount(1, $data['sections']);
        $this->assertSame(1, $data['sections'][0]['id']);
    }

    public function test_unlinked_users_and_other_roles_are_denied(): void
    {
        $this->assertSame(403, $this->schoolOptions(11)->getStatusCode());
        $this->assertSame(403, $this->schoolOptions(10, 'teacher')->getStatusCode());
    }
    public function test_director_options_are_scoped_and_revocation_removes_access(): void
    {
        DB::table('school_management_assignments')->insert([
            'school_id' => 1, 'user_id' => 30, 'role' => 'director', 'ends_at' => null,
        ]);
        $data = $this->schoolOptions(30, 'teacher')->getData(true);
        $this->assertSame(1, $data['school_id']);
        $this->assertSame([1], array_column($data['sections'], 'id'));
        DB::table('school_management_assignments')->where('user_id', 30)->update(['ends_at' => now()]);
        $this->assertSame(403, $this->schoolOptions(30, 'teacher')->getStatusCode());
    }

    public function test_ambiguous_director_school_context_is_denied(): void
    {
        DB::table('school_management_assignments')->insert([
            ['school_id' => 1, 'user_id' => 30, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 2, 'user_id' => 30, 'role' => 'director', 'ends_at' => null],
        ]);
        $this->assertSame(403, $this->schoolOptions(30, 'teacher')->getStatusCode());
    }
}
