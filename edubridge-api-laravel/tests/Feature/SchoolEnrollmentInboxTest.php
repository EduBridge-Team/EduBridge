<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolEnrollmentInboxController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolEnrollmentInboxTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active');
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->string('name');
        });
        Schema::create('school_enrollment_requests', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->unsignedInteger('version'); $t->text('reason')->nullable();
            $t->timestamps();
        });
        DB::table('schools')->insert([
            ['id'=>1,'name'=>'Own','organization_id'=>null,'is_active'=>true],
            ['id'=>2,'name'=>'Other','organization_id'=>null,'is_active'=>true],
        ]);
        DB::table('school_accounts')->insert(['school_id'=>1,'user_id'=>7]);
        DB::table('children')->insert([['id'=>1,'name'=>'First'],['id'=>2,'name'=>'Second']]);
        DB::table('school_enrollment_requests')->insert([
            ['id'=>11,'school_id'=>1,'child_id'=>1,'status'=>'pending','version'=>1,'created_at'=>now(),'updated_at'=>now()],
            ['id'=>12,'school_id'=>2,'child_id'=>2,'status'=>'pending','version'=>1,'created_at'=>now(),'updated_at'=>now()],
            ['id'=>13,'school_id'=>1,'child_id'=>2,'status'=>'cancelled','version'=>2,'created_at'=>now(),'updated_at'=>now()],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_enrollment_requests','children','school_accounts','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function inbox(int $user, string $role = 'school'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/enrollment-requests', 'GET', ['school_id'=>2]);
        $request->attributes->set('jwt_user', (object) ['id'=>$user,'role'=>$role]);
        return app(SchoolEnrollmentInboxController::class)->index($request);
    }

    public function test_only_pending_requests_from_authenticated_school_are_visible(): void
    {
        $data = $this->inbox(7)->getData(true);
        $this->assertSame(1, $data['school_id']);
        $this->assertCount(1, $data['requests']);
        $this->assertSame(11, $data['requests'][0]['id']);
        $this->assertSame('First', $data['requests'][0]['child_name']);
    }

    public function test_non_school_and_unlinked_users_are_denied(): void
    {
        $this->assertSame(403, $this->inbox(7,'parent')->getStatusCode());
        $this->assertSame(403, $this->inbox(999)->getStatusCode());
    }
}
