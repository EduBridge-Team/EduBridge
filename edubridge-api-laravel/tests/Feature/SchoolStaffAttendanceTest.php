<?php
namespace Tests\Feature;

use App\Http\Controllers\SchoolOperationsController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolStaffAttendanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) { $t->id(); $t->boolean('is_active'); });
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable(); $t->boolean('is_active'); });
        Schema::create('users', function (Blueprint $t) { $t->id(); $t->string('name'); $t->string('role'); });
        Schema::create('school_management_assignments', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id'); $t->string('role'); $t->timestamp('ends_at')->nullable(); });
        Schema::create('school_internal_identities', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id'); $t->boolean('is_active'); });
        Schema::create('school_staff_attendance', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id'); $t->date('attendance_date'); $t->string('status'); $t->unsignedBigInteger('recorded_by'); $t->timestamps(); $t->unique(['school_id','user_id','attendance_date']); });
        DB::table('schools')->insert([['id'=>1,'name'=>'Own','organization_id'=>null,'is_active'=>true],['id'=>2,'name'=>'Other','organization_id'=>null,'is_active'=>true]]);
        DB::table('users')->insert([['id'=>10,'name'=>'Director','role'=>'teacher'],['id'=>20,'name'=>'Own staff','role'=>'staff'],['id'=>30,'name'=>'Foreign staff','role'=>'staff']]);
        DB::table('school_management_assignments')->insert(['school_id'=>1,'user_id'=>10,'role'=>'director','ends_at'=>null]);
        DB::table('school_internal_identities')->insert([['school_id'=>1,'user_id'=>20,'is_active'=>true],['school_id'=>2,'user_id'=>30,'is_active'=>true]]);
    }
    protected function tearDown(): void
    {
        foreach (['school_staff_attendance','school_internal_identities','school_management_assignments','users','schools','organizations'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }
    private function mark(int $user): \Illuminate\Http\JsonResponse
    {
        $request=Request::create('/api/school/operations/staff-attendance-mark','PUT',['expected_school_id'=>1,'date'=>'2026-10-31','records'=>[['user_id'=>$user,'status'=>'present']]]);
        $request->attributes->set('jwt_user',(object)['id'=>10,'role'=>'teacher']);
        return app(SchoolOperationsController::class)->handle($request,'staff-attendance-mark');
    }
    public function test_staff_marking_is_scoped_and_repeated_save_updates_one_record(): void
    {
        $this->assertSame(200,$this->mark(20)->getStatusCode());
        $this->assertSame(200,$this->mark(20)->getStatusCode());
        $this->assertSame(1,DB::table('school_staff_attendance')->count());
        $this->assertSame(422,$this->mark(30)->getStatusCode());
        $this->assertSame(1,DB::table('school_staff_attendance')->count());
    }
    public function test_staff_roster_does_not_expose_another_school(): void
    {
        $request=Request::create('/api/school/operations/staff-attendance','GET',['date'=>'2026-10-31','school_id'=>2]);
        $request->attributes->set('jwt_user',(object)['id'=>10,'role'=>'teacher']);
        $data=app(SchoolOperationsController::class)->handle($request,'staff-attendance')->getData(true);
        $this->assertSame([10,20],array_column($data['staff'],'id'));
        DB::table('school_management_assignments')->update(['ends_at'=>now()]);
        $this->assertSame(403,$this->mark(20)->getStatusCode());
    }
}
