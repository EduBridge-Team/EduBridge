<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaAnnualPromotionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaAnnualPromotionTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->integer('position'); });
        Schema::create('academic_years', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->date('starts_on'); });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id');
            $t->unsignedInteger('capacity')->nullable();
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->date('enrolled_on'); $t->date('left_on')->nullable(); $t->timestamps();
        });
        DB::table('schools')->insert([['id'=>1,'organization_id'=>1], ['id'=>2,'organization_id'=>2]]);
        DB::table('children')->insert([['id'=>1,'organization_id'=>1], ['id'=>2,'organization_id'=>2]]);
        DB::table('grades')->insert([
            ['id'=>1,'school_id'=>1,'position'=>1],
            ['id'=>2,'school_id'=>1,'position'=>2],
            ['id'=>3,'school_id'=>2,'position'=>2],
        ]);
        DB::table('academic_years')->insert([
            ['id'=>1,'school_id'=>1,'starts_on'=>'2025-09-01'],
            ['id'=>2,'school_id'=>1,'starts_on'=>'2026-09-01'],
            ['id'=>3,'school_id'=>2,'starts_on'=>'2026-09-01'],
        ]);
        DB::table('sections')->insert([
            ['id'=>1,'grade_id'=>1,'academic_year_id'=>1,'capacity'=>30],
            ['id'=>2,'grade_id'=>2,'academic_year_id'=>2,'capacity'=>1],
            ['id'=>3,'grade_id'=>3,'academic_year_id'=>3,'capacity'=>30],
        ]);
        DB::table('student_enrollments')->insert([
            'id'=>1,'section_id'=>1,'child_id'=>1,'status'=>'active','enrolled_on'=>'2025-09-01',
            'created_at'=>now(),'updated_at'=>now(),
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['student_enrollments','sections','academic_years','grades','children','schools'] as $table)
            Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function promote(int $organization = 1, int $target = 2, string $slug = 'jabalia'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/promotion', 'POST', [
            'target_section_id'=>$target, 'promoted_on'=>'2026-09-01',
        ]);
        $request->attributes->set('organization', (object)['id'=>$organization,'slug'=>$slug]);
        return app(JabaliaAnnualPromotionController::class)->promote($request, $slug, 1, 1);
    }

    public function test_promotion_retains_previous_enrollment_and_rejects_repeat(): void
    {
        $this->assertSame(201, $this->promote()->getStatusCode());
        $this->assertDatabaseHas('student_enrollments',['id'=>1,'status'=>'transferred','left_on'=>'2026-09-01']);
        $this->assertDatabaseHas('student_enrollments',['section_id'=>2,'child_id'=>1,'status'=>'active']);
        $this->assertSame(409, $this->promote()->getStatusCode());
        $this->assertSame(2, DB::table('student_enrollments')->count());
    }

    public function test_rejects_cross_tenant_wrong_grade_and_full_destination(): void
    {
        $this->assertSame(404, $this->promote(2)->getStatusCode());
        $this->assertSame(422, $this->promote(1, 3)->getStatusCode());
        DB::table('student_enrollments')->insert([
            'section_id'=>2,'child_id'=>2,'status'=>'active','enrolled_on'=>'2026-09-01',
            'created_at'=>now(),'updated_at'=>now(),
        ]);
        $this->assertSame(409, $this->promote()->getStatusCode());
        $this->assertDatabaseHas('student_enrollments',['id'=>1,'status'=>'active']);
    }
}
