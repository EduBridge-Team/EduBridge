<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaStaffAttendanceReportController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class JabaliaStaffAttendanceReportTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->boolean('is_active');
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('role');
        });
        Schema::create('school_internal_identities', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->boolean('is_active');
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('school_staff_attendance', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->date('attendance_date'); $t->string('status'); $t->timestamps();
        });

        DB::table('organizations')->insert([
            ['id'=>1,'slug'=>'jabalia'], ['id'=>2,'slug'=>'other'],
        ]);
        DB::table('schools')->insert([
            ['id'=>10,'organization_id'=>1,'is_active'=>true],
            ['id'=>11,'organization_id'=>1,'is_active'=>true],
            ['id'=>12,'organization_id'=>2,'is_active'=>true],
        ]);
        DB::table('users')->insert([
            ['id'=>20,'name'=>'Director A','role'=>'teacher'],
            ['id'=>21,'name'=>'Staff B','role'=>'staff'],
            ['id'=>22,'name'=>'Foreign Staff','role'=>'staff'],
            ['id'=>23,'name'=>'Departed Employee','role'=>'staff'],
            ['id'=>24,'name'=>'Unrelated Teacher','role'=>'teacher'],
            ['id'=>25,'name'=>'Official School','role'=>'school'],
        ]);
        DB::table('school_management_assignments')->insert([
            ['school_id'=>10,'user_id'=>20,'role'=>'director','ends_at'=>null],
            ['school_id'=>10,'user_id'=>23,'role'=>'deputy_director','ends_at'=>now()],
        ]);
        DB::table('school_internal_identities')->insert([
            ['school_id'=>10,'user_id'=>21,'is_active'=>true],
            ['school_id'=>11,'user_id'=>22,'is_active'=>true],
            ['school_id'=>10,'user_id'=>24,'is_active'=>false],
            ['school_id'=>10,'user_id'=>25,'is_active'=>true],
        ]);
        $stamp=['created_at'=>now(),'updated_at'=>now()];
        DB::table('school_staff_attendance')->insert([
            ['school_id'=>10,'user_id'=>20,'attendance_date'=>'2026-10-05','status'=>'present',...$stamp],
            ['school_id'=>10,'user_id'=>20,'attendance_date'=>'2026-10-06','status'=>'absent',...$stamp],
            ['school_id'=>10,'user_id'=>20,'attendance_date'=>'2026-11-01','status'=>'late',...$stamp],
            ['school_id'=>10,'user_id'=>21,'attendance_date'=>'2026-10-05','status'=>'late',...$stamp],
            ['school_id'=>10,'user_id'=>21,'attendance_date'=>'2026-10-06','status'=>'excused',...$stamp],
            ['school_id'=>10,'user_id'=>23,'attendance_date'=>'2026-10-05','status'=>'absent',...$stamp],
            ['school_id'=>10,'user_id'=>24,'attendance_date'=>'2026-10-05','status'=>'present',...$stamp],
            ['school_id'=>11,'user_id'=>22,'attendance_date'=>'2026-10-05','status'=>'absent',...$stamp],
            ['school_id'=>12,'user_id'=>22,'attendance_date'=>'2026-10-05','status'=>'absent',...$stamp],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_staff_attendance','school_internal_identities',
            'school_management_assignments','users','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function request(int $org=1, string $slug='jabalia', string $role='institution', array $params=[]): Request
    {
        $request = Request::create('/api/institutions/'.$slug.'/schools/10/staff-attendance-summary',
            'GET', array_merge(['from'=>'2026-10-01','to'=>'2026-10-31'], $params));
        $request->attributes->set('organization', (object)['id'=>$org,'slug'=>$slug]);
        $request->attributes->set('jwt_user', (object)['id'=>30,'role'=>$role]);
        return $request;
    }

    public function test_school_staff_summary_counts_only_recorded_days_in_requested_period(): void
    {
        $result=app(JabaliaStaffAttendanceReportController::class)
            ->index($this->request(), 'jabalia', 10);
        $this->assertSame(200,$result->status());
        $data=$result->getData(true);
        $this->assertSame(10,$data['school_id']);
        $this->assertTrue($data['recorded_only']);
        $this->assertCount(2,$data['staff']['data']);
        $byId=collect($data['staff']['data'])->keyBy('user_id');
        $this->assertSame(2,$byId[20]['recorded_days']);
        $this->assertSame(['present'=>1,'absent'=>1,'late'=>0,'excused'=>0],
            $byId[20]['statuses']);
        $this->assertSame(2,$byId[21]['recorded_days']);
        $this->assertSame(['present'=>0,'absent'=>0,'late'=>1,'excused'=>1],
            $byId[21]['statuses']);
        $this->assertArrayNotHasKey('recorded_by',$byId[20]);
        $this->assertSame(9, DB::table('school_staff_attendance')->count());
    }

    public function test_denies_other_organization_school_role_and_unbounded_date_ranges(): void
    {
        $controller=app(JabaliaStaffAttendanceReportController::class);
        $this->assertSame(404,$controller->index($this->request(), 'jabalia', 11)->status()===404 ? 404 : 200);
        // The same institution may access its second school, but only its own roster.
        $other=$controller->index($this->request(), 'jabalia', 11)->getData(true);
        $this->assertSame([22],array_column($other['staff']['data'],'user_id'));
        $this->assertSame(404,$controller->index($this->request(), 'jabalia', 12)->status());
        $this->assertSame(404,$controller->index($this->request(2,'other'), 'other', 12)->status());
        foreach (['parent','school','teacher','specialist'] as $role) {
            $this->assertSame(404,$controller->index($this->request(1,'jabalia',$role), 'jabalia', 10)->status());
        }
        try {
            $controller->index($this->request(1,'jabalia','institution',
                ['to'=>'2027-12-31']), 'jabalia', 10);
            $this->fail('Unbounded date range should be denied');
        } catch (ValidationException $ignored) {
            // A malformed range is rejected by Laravel validation or bounded logic.
        }
    }

    public function test_unauthenticated_routes_are_protected(): void
    {
        $url='/api/institutions/jabalia/schools/10/staff-attendance-summary?from=2026-10-01&to=2026-10-31';
        $this->assertContains($this->getJson($url)->status(), [401,403]);
    }
}
