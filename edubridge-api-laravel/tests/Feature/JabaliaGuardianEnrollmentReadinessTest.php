<?php

namespace Tests\Feature;

use App\Http\Controllers\GuardianEnrollmentHistoryController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaGuardianEnrollmentReadinessTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug'); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable();
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->string('name');
        });
        Schema::create('child_parent', function (Blueprint $t) {
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id');
        });
        Schema::create('school_enrollment_requests', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('school_id');
            $t->string('status'); $t->unsignedInteger('version'); $t->text('reason')->nullable(); $t->timestamps();
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('section_id');
            $t->string('status');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
        });

        DB::table('organizations')->insert([
            ['id'=>1, 'slug'=>'jabalia', 'is_active'=>true],
            ['id'=>2, 'slug'=>'another', 'is_active'=>true],
        ]);
        DB::table('schools')->insert([
            ['id'=>10, 'name'=>'Jabalia School', 'organization_id'=>1],
            ['id'=>20, 'name'=>'Other School', 'organization_id'=>2],
            ['id'=>30, 'name'=>'Standalone', 'organization_id'=>null],
        ]);
        DB::table('children')->insert([['id'=>4,'name'=>'Own'],['id'=>5,'name'=>'Foreign']]);
        DB::table('child_parent')->insert(['child_id'=>4,'parent_id'=>2]);
        DB::table('school_enrollment_requests')->insert([
            ['id'=>100,'reason'=>null,'child_id'=>4,'school_id'=>10,'status'=>'pending','version'=>1,'created_at'=>now(),'updated_at'=>now()],
            ['id'=>101,'child_id'=>4,'school_id'=>20,'status'=>'rejected','version'=>2,'reason'=>'No room','created_at'=>now(),'updated_at'=>now()],
            ['id'=>102,'reason'=>null,'child_id'=>4,'school_id'=>30,'status'=>'cancelled','version'=>2,'created_at'=>now(),'updated_at'=>now()],
            ['id'=>103,'reason'=>null,'child_id'=>5,'school_id'=>10,'status'=>'pending','version'=>1,'created_at'=>now(),'updated_at'=>now()],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['student_enrollments','sections','grades','school_enrollment_requests',
            'child_parent','children','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function history(int $parent, int $child): \Illuminate\Http\JsonResponse
    {
        $req = Request::create('/api/parent/children/'.$child.'/enrollment-requests', 'GET');
        $req->attributes->set('jwt_user', (object)['id'=>$parent,'role'=>'parent']);
        return app(GuardianEnrollmentHistoryController::class)->index($req, $child);
    }

    public function test_jabalia_flag_is_per_request_with_no_tenant_slug_exposed(): void
    {
        $response = $this->history(2, 4);
        $this->assertSame(200, $response->status());
        $data = $response->getData(true);
        $this->assertCount(3, $data['requests']);
        $byId = collect($data['requests'])->keyBy('id');
        $this->assertTrue($byId[100]['requires_counselor_review']);
        $this->assertFalse($byId[101]['requires_counselor_review']);
        $this->assertFalse($byId[102]['requires_counselor_review']);
        foreach ($data['requests'] as $row) $this->assertArrayNotHasKey('tenant_slug', $row);
    }

    public function test_unrelated_parent_cannot_learn_a_child_jabalia_history(): void
    {
        $this->assertSame(404, $this->history(99, 4)->status());
        $this->assertSame(404, $this->history(2, 5)->status());
    }
}
