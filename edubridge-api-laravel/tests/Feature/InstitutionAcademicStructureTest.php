<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionAcademicController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionAcademicStructureTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('slug')->nullable(); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->foreignId('organization_id'); $t->string('name'); $t->string('slug'); $t->timestamps();
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id(); $t->foreignId('school_id'); $t->string('name'); $t->date('starts_on'); $t->date('ends_on'); $t->boolean('is_current')->default(false); $t->timestamps();
            $t->unique(['school_id', 'name']);
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->foreignId('school_id'); $t->string('name'); $t->string('code')->nullable(); $t->unsignedSmallInteger('position')->default(1); $t->boolean('is_active')->default(true); $t->timestamps();
        });
        Schema::create('subjects', function (Blueprint $t) {
            $t->id(); $t->foreignId('school_id'); $t->string('name'); $t->string('code')->nullable(); $t->string('color')->nullable(); $t->boolean('is_active')->default(true); $t->timestamps();
        });

        DB::table('organizations')->insert([
            ['id' => 1, 'name' => 'جمعية جباليا للتأهيل', 'slug' => 'jabalia', 'is_active' => true],
            ['id' => 2, 'name' => 'Other', 'slug' => 'other', 'is_active' => true],
        ]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => 1, 'name' => 'Jabalia School', 'slug' => 'main', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 20, 'organization_id' => 2, 'name' => 'Other School', 'slug' => 'main', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('subjects');
        Schema::dropIfExists('grades');
        Schema::dropIfExists('academic_years');
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    public function test_academic_year_is_created_inside_current_tenant_school(): void
    {
        $request = Request::create('/api/institutions/jabalia/schools/10/academic/years', 'POST', [
            'name' => '2026/2027',
            'starts_on' => '2026-09-01',
            'ends_on' => '2027-06-30',
            'is_current' => true,
        ]);
        $request->attributes->set('organization', (object) ['id' => 1, 'slug' => 'jabalia']);

        $response = app(InstitutionAcademicController::class)->storeAcademicYear($request, 'jabalia', 10);

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('academic_years', ['school_id' => 10, 'name' => '2026/2027', 'is_current' => true]);
    }

    public function test_other_tenant_school_is_hidden_even_when_id_is_known(): void
    {
        $request = Request::create('/api/institutions/jabalia/schools/20/academic', 'GET');
        $request->attributes->set('organization', (object) ['id' => 1, 'slug' => 'jabalia']);

        $response = app(InstitutionAcademicController::class)->overview($request, 'jabalia', 20);

        $this->assertSame(404, $response->getStatusCode());
    }

    public function test_only_one_current_academic_year_remains_per_school(): void
    {
        DB::table('academic_years')->insert([
            'school_id' => 10, 'name' => '2025/2026', 'starts_on' => '2025-09-01', 'ends_on' => '2026-06-30',
            'is_current' => true, 'created_at' => now(), 'updated_at' => now(),
        ]);

        $request = Request::create('/api/institutions/jabalia/schools/10/academic/years', 'POST', [
            'name' => '2026/2027', 'starts_on' => '2026-09-01', 'ends_on' => '2027-06-30', 'is_current' => true,
        ]);
        $request->attributes->set('organization', (object) ['id' => 1, 'slug' => 'jabalia']);

        app(InstitutionAcademicController::class)->storeAcademicYear($request, 'jabalia', 10);

        $this->assertSame(1, DB::table('academic_years')->where('school_id', 10)->where('is_current', true)->count());
        $this->assertDatabaseHas('academic_years', ['school_id' => 10, 'name' => '2025/2026', 'is_current' => false]);
    }
}
