<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolOperationsController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaSchoolTimetablePermissionsTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', fn (Blueprint $t) => tap($t->id(), fn () => $t->string('slug')));
        Schema::table('organizations', fn (Blueprint $t) => $t->boolean('is_active')->default(true));
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->boolean('is_active')->default(true);
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->json('permissions')->nullable(); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('jabalia_school_timetable_settings', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id')->unique(); $t->json('weekdays'); $t->json('periods'); $t->timestamps();
        });
        Schema::create('timetable_entries', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
            $t->integer('weekday'); $t->integer('period_number'); $t->time('starts_at')->nullable(); $t->time('ends_at')->nullable();
        });
        Schema::create('jabalia_section_subject_quotas', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('section_id');
            $t->unsignedBigInteger('subject_id'); $t->integer('weekly_periods'); $t->timestamps();
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id');
        });
        Schema::create('subjects', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
        });
        DB::table('organizations')->insert(['id'=>1,'slug'=>'jabalia','is_active'=>true]);
        DB::table('schools')->insert([['id'=>1,'organization_id'=>1,'is_active'=>true],['id'=>2,'organization_id'=>1,'is_active'=>true]]);
        DB::table('school_accounts')->insert(['school_id'=>1,'user_id'=>10]);
        DB::table('school_management_assignments')->insert([
            ['school_id'=>1,'user_id'=>20,'role'=>'director','permissions'=>null,'ends_at'=>null],
            ['school_id'=>1,'user_id'=>30,'role'=>'deputy_director','permissions'=>json_encode(['attendance']),'ends_at'=>null],
            ['school_id'=>1,'user_id'=>40,'role'=>'deputy_director','permissions'=>json_encode(['timetable']),'ends_at'=>null],
        ]);
        DB::table('grades')->insert([['id'=>1,'school_id'=>1],['id'=>2,'school_id'=>2]]);
        DB::table('sections')->insert([['id'=>1,'grade_id'=>1,'academic_year_id'=>1],['id'=>2,'grade_id'=>2,'academic_year_id'=>1]]);
        DB::table('subjects')->insert([['id'=>1,'school_id'=>1],['id'=>2,'school_id'=>2]]);
    }

    protected function tearDown(): void
    {
        foreach (['subjects','sections','grades','jabalia_section_subject_quotas','timetable_entries',
            'jabalia_school_timetable_settings','school_management_assignments','school_accounts','schools','organizations'] as $table)
            Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function operation(int $user, string $action, string $method = 'GET', array $body = []): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/operations/'.$action, $method, $body);
        $request->attributes->set('jwt_user', (object)['id'=>$user,'role'=>$user===10?'school':'teacher']);
        return app(SchoolOperationsController::class)->handle($request, $action);
    }

    public function test_school_account_and_director_can_read_schedule_configuration(): void
    {
        $this->assertSame(200, $this->operation(10, 'timetable-settings')->getStatusCode());
        $this->assertSame(200, $this->operation(20, 'timetable-settings')->getStatusCode());
    }

    public function test_deputy_must_have_timetable_delegation(): void
    {
        $this->assertSame(403, $this->operation(30, 'timetable-settings')->getStatusCode());
        $this->assertSame(200, $this->operation(40, 'timetable-settings')->getStatusCode());
        $this->assertSame(403, $this->operation(30, 'subject-quotas')->getStatusCode());
    }

    public function test_school_scope_is_server_enforced_for_write(): void
    {
        $payload = ['expected_school_id'=>2,'weekdays'=>[7],
            'periods'=>[['starts_at'=>'08:30','ends_at'=>'09:10']]];
        $this->assertSame(422, $this->operation(20,'timetable-settings-update','PUT',$payload)->getStatusCode());
        $this->assertSame(0, DB::table('jabalia_school_timetable_settings')->count());
        $payload['expected_school_id']=1;
        $this->assertSame(200, $this->operation(20,'timetable-settings-update','PUT',$payload)->getStatusCode());
        $this->assertSame(1,(int) DB::table('jabalia_school_timetable_settings')->value('school_id'));
    }

    public function test_foreign_section_and_subject_quotas_are_denied(): void
    {
        $payload=['expected_school_id'=>1,'section_id'=>2,'subject_id'=>2,'weekly_periods'=>4];
        $this->assertSame(422, $this->operation(40,'subject-quotas-update','PUT',$payload)->getStatusCode());
        $this->assertSame(0,DB::table('jabalia_section_subject_quotas')->count());
    }

    public function test_revoked_deputy_loses_access(): void
    {
        DB::table('school_management_assignments')->where('user_id',40)->update(['ends_at'=>now()]);
        $this->assertSame(403, $this->operation(40, 'timetable-settings')->getStatusCode());
    }
}
