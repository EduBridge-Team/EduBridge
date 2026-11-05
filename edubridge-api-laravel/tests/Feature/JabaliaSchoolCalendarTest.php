<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaSchoolCalendarController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaSchoolCalendarTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id');
        });
        Schema::create('attendance_sessions', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id');
            $t->date('attendance_date'); $t->unsignedTinyInteger('period_number')->nullable();
        });
        Schema::create('jabalia_school_closure_days', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id'); $t->date('closed_on');
            $t->string('reason'); $t->unsignedBigInteger('created_by')->nullable();
            $t->timestamps(); $t->unique(['school_id', 'closed_on']);
        });
        Schema::create('jabalia_school_closure_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id'); $t->date('closed_on');
            $t->string('action'); $t->string('reason');
            $t->unsignedBigInteger('actor_id')->nullable(); $t->timestamp('created_at');
        });
        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia'],
            ['id' => 2, 'slug' => 'other'],
        ]);
        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => 1],
            ['id' => 2, 'organization_id' => 1],
            ['id' => 3, 'organization_id' => 2],
        ]);
        DB::table('grades')->insert([
            ['id' => 1, 'school_id' => 1],
            ['id' => 2, 'school_id' => 2],
        ]);
        DB::table('sections')->insert([
            ['id' => 1, 'grade_id' => 1],
            ['id' => 2, 'grade_id' => 2],
        ]);
    }

    protected function tearDown(): void
    {
        foreach ([
            'jabalia_school_closure_events', 'jabalia_school_closure_days',
            'attendance_sessions', 'sections', 'grades', 'schools', 'organizations',
        ] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function request(array $data = [], int $org = 1, string $slug = 'jabalia'): Request
    {
        $request = Request::create('/api/institutions/'.$slug.'/schools/1/closure-days', 'POST', $data);
        $request->attributes->set('organization', (object) ['id' => $org, 'slug' => $slug]);
        $request->attributes->set('jwt_user', (object) ['id' => 30, 'role' => 'institution']);
        return $request;
    }

    public function test_create_duplicate_audit_and_remove(): void
    {
        $controller = app(JabaliaSchoolCalendarController::class);
        $data = ['closed_on' => '2026-11-10', 'reason' => 'Approved school closure'];
        $response = $controller->store($this->request($data), 'jabalia', 1);
        $this->assertSame(201, $response->status());
        $id = $response->getData(true)['day']['id'];
        $this->assertSame(409, $controller->store($this->request($data), 'jabalia', 1)->status());
        $this->assertSame(1, DB::table('jabalia_school_closure_days')->count());
        $this->assertSame(30, (int) DB::table('jabalia_school_closure_events')->value('actor_id'));
        $listed = $controller->index($this->request(), 'jabalia', 1)->getData(true);
        $this->assertCount(1, $listed['days']);
        $this->assertCount(1, $listed['recent_changes']);

        $this->assertSame(404, $controller->destroy($this->request(), 'jabalia', 2, $id)->status());
        $this->assertSame(200, $controller->destroy($this->request(), 'jabalia', 1, $id)->status());
        $this->assertSame(404, $controller->destroy($this->request(), 'jabalia', 1, $id)->status());
        $this->assertSame(0, DB::table('jabalia_school_closure_days')->count());
        $this->assertSame(['created', 'removed'],
            DB::table('jabalia_school_closure_events')->orderBy('id')->pluck('action')->all());
    }

    public function test_only_jabalia_and_requested_school_can_access_calendar(): void
    {
        $controller = app(JabaliaSchoolCalendarController::class);
        $data = ['closed_on' => '2026-11-10', 'reason' => 'Official closure'];
        $this->assertSame(404, $controller->index($this->request([], 2, 'other'), 'other', 1)->status());
        $this->assertSame(404, $controller->store($this->request($data, 2, 'other'), 'other', 1)->status());
        $this->assertSame(404, $controller->store($this->request($data), 'jabalia', 3)->status());
        $this->assertSame(0, DB::table('jabalia_school_closure_days')->count());

        $this->assertSame(201, $controller->store($this->request($data), 'jabalia', 1)->status());
        $this->assertCount(0, $controller->index($this->request(), 'jabalia', 2)->getData(true)['days']);
    }

    public function test_existing_attendance_blocks_closure_and_reopening(): void
    {
        $controller = app(JabaliaSchoolCalendarController::class);
        DB::table('attendance_sessions')->insert([
            'section_id' => 1, 'attendance_date' => '2026-11-11',
        ]);
        $this->assertSame(409, $controller->store($this->request([
            'closed_on' => '2026-11-11', 'reason' => 'Already has attendance',
        ]), 'jabalia', 1)->status());
        $this->assertSame(0, DB::table('jabalia_school_closure_days')->count());
        $this->assertSame(201, $controller->store($this->request([
            'closed_on' => '2026-11-12', 'reason' => 'Tomorrow closure',
        ]), 'jabalia', 1)->status());
        $id = DB::table('jabalia_school_closure_days')->value('id');
        DB::table('attendance_sessions')->insert([
            'section_id' => 1, 'attendance_date' => '2026-11-12',
        ]);
        $this->assertSame(409, $controller->destroy($this->request(), 'jabalia', 1, $id)->status());
        $this->assertSame(1, DB::table('jabalia_school_closure_days')->count());
    }

    public function test_short_or_invalid_reason_never_creates_calendar_record(): void
    {
        $controller = app(JabaliaSchoolCalendarController::class);
        try {
            $controller->store($this->request([
                'closed_on' => '2026-11-15', 'reason' => '   ',
            ]), 'jabalia', 1);
            $this->fail('Whitespace-only reason should fail validation.');
        } catch (\Illuminate\Validation\ValidationException $exception) {
            $this->assertArrayHasKey('reason', $exception->errors());
        }

        $response = $controller->store($this->request([
            'closed_on' => '2026-11-15', 'reason' => '  X   ',
        ]), 'jabalia', 1);
        $this->assertSame(422, $response->status());
        $this->assertSame(0, DB::table('jabalia_school_closure_days')->count());
    }
}
