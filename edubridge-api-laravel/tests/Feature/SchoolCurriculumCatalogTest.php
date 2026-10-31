<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolCurriculumCatalogController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolCurriculumCatalogTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active');
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('user_id'); $t->unsignedBigInteger('school_id');
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
            $t->date('starts_on'); $t->date('ends_on'); $t->boolean('is_current');
        });
        Schema::create('academic_terms', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('academic_year_id'); $t->string('name');
            $t->integer('position'); $t->date('starts_on'); $t->date('ends_on');
        });
        Schema::create('subjects', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
            $t->string('code')->nullable(); $t->boolean('is_active');
        });
        DB::table('schools')->insert([
            ['id' => 1, 'name' => 'School A', 'is_active' => true, 'organization_id' => null],
            ['id' => 2, 'name' => 'School B', 'is_active' => true, 'organization_id' => null],
        ]);
        DB::table('school_accounts')->insert(['user_id' => 10, 'school_id' => 1]);
        DB::table('academic_years')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => '2026/2027', 'starts_on' => '2026-09-01', 'ends_on' => '2027-06-30', 'is_current' => true],
            ['id' => 2, 'school_id' => 2, 'name' => 'Other', 'starts_on' => '2026-09-01', 'ends_on' => '2027-06-30', 'is_current' => true],
        ]);
        DB::table('academic_terms')->insert([
            ['id' => 1, 'academic_year_id' => 1, 'name' => 'First', 'position' => 1, 'starts_on' => '2026-09-01', 'ends_on' => '2026-12-31'],
            ['id' => 2, 'academic_year_id' => 2, 'name' => 'Foreign', 'position' => 1, 'starts_on' => '2026-09-01', 'ends_on' => '2026-12-31'],
        ]);
        DB::table('subjects')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'Math', 'code' => null, 'is_active' => true],
            ['id' => 2, 'school_id' => 2, 'name' => 'Foreign', 'code' => null, 'is_active' => true],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['subjects', 'academic_terms', 'academic_years', 'school_accounts', 'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        Schema::dropIfExists('school_management_assignments');
        parent::tearDown();
    }

    private function getCatalog(int $id, string $role = 'school'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/academic/curriculum', 'GET', ['school_id' => 2]);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        return app(SchoolCurriculumCatalogController::class)->index($request);
    }

    public function test_catalog_is_scoped_to_account_school(): void
    {
        $response = $this->getCatalog(10);
        $this->assertSame(200, $response->getStatusCode());
        $data = $response->getData(true);
        $this->assertSame(['id' => 1, 'name' => 'School A'], $data['school']);
        $this->assertSame([1], array_column($data['academic_years'], 'id'));
        $this->assertSame([1], array_column($data['academic_terms'], 'id'));
        $this->assertSame([1], array_column($data['subjects'], 'id'));
        $this->assertSame(true, $data['academic_years'][0]['is_current']);
    }

    public function test_unlinked_or_wrong_role_is_denied(): void
    {
        $this->assertSame(403, $this->getCatalog(20)->getStatusCode());
        $this->assertSame(403, $this->getCatalog(10, 'teacher')->getStatusCode());
    }
    public function test_personal_director_access_is_revoked_with_assignment(): void
    {
        DB::table('school_management_assignments')->insert([
            'school_id' => 1, 'user_id' => 30, 'role' => 'director', 'ends_at' => null,
        ]);
        $this->assertSame(200, $this->getCatalog(30, 'teacher')->getStatusCode());
        DB::table('school_management_assignments')->where('user_id', 30)->update(['ends_at' => now()]);
        $this->assertSame(403, $this->getCatalog(30, 'teacher')->getStatusCode());
    }
}
