<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaBulkPromotionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaBulkPromotionApprovalTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id'); });
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
        DB::table('children')->insert([
            ['id'=>1,'name'=>'A','organization_id'=>1],
            ['id'=>2,'name'=>'B','organization_id'=>1],
        ]);
        DB::table('grades')->insert([
            ['id'=>1,'school_id'=>1,'position'=>1],
            ['id'=>2,'school_id'=>1,'position'=>2],
        ]);
        DB::table('academic_years')->insert([
            ['id'=>1,'school_id'=>1,'starts_on'=>'2025-09-01'],
            ['id'=>2,'school_id'=>1,'starts_on'=>'2026-09-01'],
        ]);
        DB::table('sections')->insert([
            ['id'=>1,'grade_id'=>1,'academic_year_id'=>1,'capacity'=>30],
            ['id'=>2,'grade_id'=>2,'academic_year_id'=>2,'capacity'=>2],
        ]);
        DB::table('student_enrollments')->insert([
            ['id'=>1,'section_id'=>1,'child_id'=>1,'status'=>'active',
                'enrolled_on'=>'2025-09-01','created_at'=>now(),'updated_at'=>now()],
            ['id'=>2,'section_id'=>1,'child_id'=>2,'status'=>'active',
                'enrolled_on'=>'2025-09-01','created_at'=>now(),'updated_at'=>now()],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['student_enrollments','sections','academic_years','grades','children','schools'] as $table)
            Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function approve(array $ids, int $org = 1): \Illuminate\Http\JsonResponse
    {
        $req = Request::create('/bulk-promotion-approve', 'POST', [
            'source_section_id'=>1,'target_section_id'=>2,'promoted_on'=>'2026-09-01',
            'enrollment_ids'=>$ids,'confirm'=>true,
        ]);
        $req->attributes->set('organization', (object)['id'=>$org,'slug'=>'jabalia']);
        return app(JabaliaBulkPromotionController::class)->approve($req, 'jabalia', 1);
    }

    public function test_approves_two_students_and_preserves_history(): void
    {
        $response = $this->approve([1,2]);
        $this->assertSame(201, $response->getStatusCode());
        $this->assertSame(2, $response->getData(true)['promoted_count']);
        $this->assertDatabaseHas('student_enrollments', ['id'=>1,'status'=>'transferred']);
        $this->assertDatabaseHas('student_enrollments', ['id'=>2,'status'=>'transferred']);
        $this->assertSame(2, DB::table('student_enrollments')->where('section_id',2)->where('status','active')->count());
        $this->assertSame(4, DB::table('student_enrollments')->count());
        $this->assertSame(409, $this->approve([1,2])->getStatusCode());
    }

    public function test_rejects_when_capacity_insufficient_without_modifying_source(): void
    {
        DB::table('sections')->where('id',2)->update(['capacity'=>1]);
        $this->assertSame(409, $this->approve([1,2])->getStatusCode());
        $this->assertSame(2, DB::table('student_enrollments')->where('status','active')->count());
        $this->assertSame(2, DB::table('student_enrollments')->count());
    }

    public function test_rejects_cross_tenant_and_stale_enrollment_id(): void
    {
        $this->assertSame(404, $this->approve([1],2)->getStatusCode());
        $this->assertSame(409, $this->approve([1,999])->getStatusCode());
        $this->assertSame(2, DB::table('student_enrollments')->count());
    }
}
