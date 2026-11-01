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
        try {
            $this->operation(20,'timetable-settings-update','PUT',$payload);
            $this->fail('Expected validation exception for foreign school id');
        } catch (\Illuminate\Validation\ValidationException $exception) {
            $this->assertArrayHasKey('expected_school_id', $exception->errors());
        }
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

    public function test_overlapping_periods_are_rejected_without_changing_settings(): void
    {
        $response = $this->operation(20, 'timetable-settings-update', 'PUT', [
            'expected_school_id'=>1, 'weekdays'=>[7,1],
            'periods'=>[
                ['starts_at'=>'08:30','ends_at'=>'09:10'],
                ['starts_at'=>'09:00','ends_at'=>'09:50'],
            ],
        ]);
        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame(0, DB::table('jabalia_school_timetable_settings')->count());
    }

    public function test_updated_times_cannot_invalidate_existing_lessons(): void
    {
        DB::table('timetable_entries')->insert([
            'school_id'=>1, 'weekday'=>7, 'period_number'=>1,
            'starts_at'=>'08:30:00', 'ends_at'=>'09:10:00',
        ]);
        $response = $this->operation(20, 'timetable-settings-update', 'PUT', [
            'expected_school_id'=>1, 'weekdays'=>[7],
            'periods'=>[['starts_at'=>'09:00','ends_at'=>'09:40']],
        ]);
        $this->assertSame(409, $response->getStatusCode());
        $this->assertSame(0, DB::table('jabalia_school_timetable_settings')->count());
    }

    public function test_authorized_deputy_can_update_own_school_quotas(): void
    {
        $response = $this->operation(40, 'subject-quotas-update', 'PUT', [
            'expected_school_id'=>1, 'section_id'=>1, 'subject_id'=>1,
            'weekly_periods'=>4,
        ]);
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame(4, (int) DB::table('jabalia_section_subject_quotas')
            ->where('school_id', 1)->value('weekly_periods'));
        $this->assertSame(403, $this->operation(30, 'subject-quotas-update', 'PUT', [
            'expected_school_id'=>1, 'section_id'=>1, 'subject_id'=>1,
            'weekly_periods'=>2,
        ])->getStatusCode());
        $this->assertSame(4, (int) DB::table('jabalia_section_subject_quotas')->value('weekly_periods'));
    }

    public function test_nonsequential_period_keys_are_rejected(): void
    {
        try {
            $this->operation(20, 'timetable-settings-update', 'PUT', [
                'expected_school_id'=>1, 'weekdays'=>[7],
                'periods'=>[2 => ['starts_at'=>'08:30','ends_at'=>'09:10']],
            ]);
            $this->fail('Expected list validation to reject nonsequential periods');
        } catch (\Illuminate\Validation\ValidationException $exception) {
            $this->assertArrayHasKey('periods', $exception->errors());
        }
        $this->assertSame(0, DB::table('jabalia_school_timetable_settings')->count());
    }

    public function test_weekly_quotas_cannot_exceed_school_capacity(): void
    {
        DB::table('subjects')->insert(['id'=>3,'school_id'=>1]);
        $this->assertSame(200, $this->operation(20, 'subject-quotas-update', 'PUT', [
            'expected_school_id'=>1, 'section_id'=>1,'subject_id'=>1,'weekly_periods'=>24,
        ])->getStatusCode());
        $response = $this->operation(20, 'subject-quotas-update', 'PUT', [
            'expected_school_id'=>1, 'section_id'=>1,'subject_id'=>3,'weekly_periods'=>2,
        ]);
        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame(25, $response->getData(true)['capacity']);
        $this->assertSame(1, DB::table('jabalia_section_subject_quotas')->count());
    }

    public function test_revoked_deputy_loses_access(): void
    {
        DB::table('school_management_assignments')->where('user_id',40)->update(['ends_at'=>now()]);
        $this->assertSame(403, $this->operation(40, 'timetable-settings')->getStatusCode());
    }
    public function test_duplicate_weekdays_are_rejected_without_persisting_settings(): void
    {
        try {
            $this->operation(20, 'timetable-settings-update', 'PUT', [
                'expected_school_id' => 1,
                'weekdays' => [7, 7],
                'periods' => [['starts_at' => '08:30', 'ends_at' => '09:10']],
            ]);
            $this->fail('Expected duplicate weekdays validation to fail');
        } catch (\Illuminate\Validation\ValidationException $exception) {
            $this->assertArrayHasKey('weekdays.1', $exception->errors());
        }
        $this->assertSame(0, DB::table('jabalia_school_timetable_settings')->count());
    }

    public function test_reversed_period_is_rejected_without_persisting_settings(): void
    {
        $response = $this->operation(20, 'timetable-settings-update', 'PUT', [
            'expected_school_id' => 1,
            'weekdays' => [7],
            'periods' => [['starts_at' => '09:10', 'ends_at' => '08:30']],
        ]);
        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame(0, DB::table('jabalia_school_timetable_settings')->count());
    }

    public function test_removing_day_with_existing_lesson_is_rejected(): void
    {
        DB::table('timetable_entries')->insert([
            'school_id' => 1, 'weekday' => 7, 'period_number' => 1,
            'starts_at' => '08:30:00', 'ends_at' => '09:10:00',
        ]);
        $response = $this->operation(20, 'timetable-settings-update', 'PUT', [
            'expected_school_id' => 1,
            'weekdays' => [1],
            'periods' => [['starts_at' => '08:30', 'ends_at' => '09:10']],
        ]);
        $this->assertSame(409, $response->getStatusCode());
        $this->assertSame(0, DB::table('jabalia_school_timetable_settings')->count());
    }

}
