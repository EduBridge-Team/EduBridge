<?php
namespace Tests\Feature;
use App\Http\Controllers\SchoolAnnualPromotionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;
class SchoolAnnualPromotionContractTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) { $t->id(); $t->boolean('is_active'); });
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->string('name')->default('School'); $t->boolean('is_active')->default(true); $t->unsignedBigInteger('organization_id')->nullable(); });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable(); });
        Schema::create('grades', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->integer('position'); });
        Schema::create('academic_years', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->date('starts_on'); });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id');
            $t->unsignedInteger('capacity')->nullable(); $t->string('name')->default('Section');
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->date('enrolled_on'); $t->date('left_on')->nullable(); $t->timestamps();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id'); $t->string('role'); $t->timestamp('ends_at')->nullable(); });
        Schema::create('school_promotion_previews', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('actor_id'); $t->string('token_hash')->unique(); $t->string('payload_hash'); $t->timestamp('expires_at'); $t->timestamp('used_at')->nullable(); $t->timestamps(); });
        Schema::create('school_promotion_operations', function (Blueprint $t) { $t->string('operation_id')->primary(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('actor_id'); $t->unsignedBigInteger('source_year_id'); $t->unsignedBigInteger('target_year_id'); $t->string('payload_hash'); $t->text('receipt'); $t->text('decisions'); $t->timestamps(); });
        DB::table('organizations')->insert([['id'=>1,'is_active'=>true], ['id'=>2,'is_active'=>true]]);
        DB::table('school_management_assignments')->insert(['school_id'=>1, 'user_id'=>10, 'role'=>'director']);
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
        foreach (['school_promotion_operations','school_promotion_previews','school_management_assignments','organizations','student_enrollments','sections','academic_years','grades','children','schools'] as $table)
            Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function request(string $method, array $data, int $actor = 10): Request
    {
        $request = Request::create('/api/school/annual-promotion', $method, $data);
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => 'teacher']);
        return $request;
    }

    private function draft(): array
    {
        $data = app(SchoolAnnualPromotionController::class)->roster($this->request('GET', ['source_year_id'=>1,'target_year_id'=>2]))->getData(true);
        return ['source_year_id'=>1,'target_year_id'=>2,'roster_revision'=>$data['revision'], 'decisions'=>[
            ['enrollment_id'=>1,'decision'=>'promoted','target_section_id'=>2],
            ['enrollment_id'=>2,'decision'=>'promoted','target_section_id'=>2],
        ]];
    }

    private function preview(array $draft): array
    {
        return app(SchoolAnnualPromotionController::class)->preview($this->request('POST', $draft))->getData(true);
    }

    public function test_preview_approval_replay_and_recovery_preserve_history(): void
    {
        $draft = $this->draft(); $preview = $this->preview($draft);
        $this->assertTrue($preview['ready']);
        $this->assertNotSame($preview['preview_token'], DB::table('school_promotion_previews')->value('token_hash'));
        $body = [...$draft, 'preview_token'=>$preview['preview_token'], 'idempotency_key'=>'operation_123456789'];
        $controller = app(SchoolAnnualPromotionController::class);
        $first = $controller->approve($this->request('POST', $body));
        $this->assertSame(200, $first->getStatusCode());
        $this->assertSame(2, $first->getData(true)['counts']['promoted']);
        $this->assertSame($first->getData(true), $controller->approve($this->request('POST', $body))->getData(true));
        $this->assertSame(4, DB::table('student_enrollments')->count());
        $this->assertSame($first->getData(true), $controller->operation($this->request('GET', []), 'operation_123456789')->getData(true));
        $history = $controller->history($this->request('GET', ['year_id'=>1]))->getData(true);
        $this->assertTrue($history['complete']); $this->assertCount(1, $history['operations']);
    }

    public function test_changed_roster_or_capacity_blocks_approval_without_writes(): void
    {
        $draft = $this->draft(); $preview = $this->preview($draft);
        DB::table('sections')->where('id',2)->update(['capacity'=>1]);
        $response = app(SchoolAnnualPromotionController::class)->approve($this->request('POST', [...$draft,
            'preview_token'=>$preview['preview_token'], 'idempotency_key'=>'operation_123456789']));
        $this->assertSame(409, $response->getStatusCode());
        $this->assertSame(2, DB::table('student_enrollments')->where('status','active')->count());
        $this->assertSame(0, DB::table('school_promotion_operations')->count());
    }

    public function test_partial_and_foreign_decisions_cannot_receive_approval_token(): void
    {
        $draft = $this->draft(); array_pop($draft['decisions']);
        $this->assertFalse($this->preview($draft)['ready']);
        $draft = $this->draft(); $draft['decisions'][1]['enrollment_id'] = 999;
        $this->assertFalse($this->preview($draft)['ready']);
        $this->assertSame(0, DB::table('school_promotion_previews')->count());
    }

    public function test_expired_preview_and_revoked_director_cannot_approve(): void
    {
        $draft = $this->draft(); $preview = $this->preview($draft);
        $body = [...$draft, 'preview_token'=>$preview['preview_token'], 'idempotency_key'=>'operation_123456789'];
        DB::table('school_promotion_previews')->update(['expires_at'=>now()->subMinute()]);
        $this->assertSame(409, app(SchoolAnnualPromotionController::class)->approve($this->request('POST',$body))->getStatusCode());
        DB::table('school_management_assignments')->update(['ends_at'=>now()]);
        $this->assertSame(403, app(SchoolAnnualPromotionController::class)->approve($this->request('POST',$body))->getStatusCode());
        $this->assertSame(2, DB::table('student_enrollments')->count());
    }

    public function test_repeating_students_enter_same_grade_in_later_year(): void
    {
        DB::table('sections')->where('id',2)->update(['grade_id'=>1]);
        $draft = $this->draft();
        foreach ($draft['decisions'] as &$decision) $decision['decision']='repeating';
        unset($decision);
        $preview = $this->preview($draft); $this->assertTrue($preview['ready']);
        $response = app(SchoolAnnualPromotionController::class)->approve($this->request('POST', [...$draft,
            'preview_token'=>$preview['preview_token'],'idempotency_key'=>'operation_123456789']));
        $this->assertSame(2, $response->getData(true)['counts']['repeating']);
        $this->assertSame(2, DB::table('student_enrollments')->where('section_id',2)->where('status','active')->count());
    }

    public function test_transfer_records_source_exit_without_granting_destination_enrollment(): void
    {
        $draft=$this->draft(); $draft['decisions'][0]=['enrollment_id'=>1,'decision'=>'transferred','target_school_id'=>2];
        $preview=$this->preview($draft); $this->assertTrue($preview['ready']);
        $response=app(SchoolAnnualPromotionController::class)->approve($this->request('POST', [...$draft,
            'preview_token'=>$preview['preview_token'],'idempotency_key'=>'operation_123456789']));
        $this->assertSame(1,$response->getData(true)['counts']['transferred']);
        $this->assertSame('source_school_only',$response->getData(true)['transfer_scope']);
        $this->assertSame(0,DB::table('student_enrollments')->where('child_id',1)->where('status','active')->count());
        $this->assertSame(1,DB::table('student_enrollments')->where('child_id',1)->count());
    }
    public function test_unassigned_actor_cannot_read_or_prepare_promotion(): void
    {
        $controller = app(SchoolAnnualPromotionController::class);
        $query = ['source_year_id' => 1, 'target_year_id' => 2];
        $this->assertSame(403, $controller->roster($this->request('GET', $query, 99))->getStatusCode());
        $this->assertSame(403, $controller->destinations($this->request('GET', [], 99))->getStatusCode());
        $this->assertSame(403, $controller->history($this->request('GET', ['year_id' => 1], 99))->getStatusCode());
        $this->assertSame(403, $controller->operation($this->request('GET', [], 99), 'unknown')->getStatusCode());
        $this->assertSame(403, $controller->preview($this->request('POST', [
            ...$query, 'roster_revision' => str_repeat('a', 64),
            'decisions' => [['enrollment_id' => 1, 'decision' => 'promoted', 'target_section_id' => 2]],
        ], 99))->getStatusCode());
        $this->assertSame(0, DB::table('school_promotion_previews')->count());
        $this->assertSame(2, DB::table('student_enrollments')->count());
    }

    public function test_promotion_cannot_access_second_school_when_directorship_is_ambiguous(): void
    {
        DB::table('school_management_assignments')->insert([
            'school_id' => 2, 'user_id' => 10, 'role' => 'director', 'ends_at' => null,
        ]);
        $controller = app(SchoolAnnualPromotionController::class);
        $this->assertSame(403, $controller->roster($this->request('GET', [
            'source_year_id' => 1, 'target_year_id' => 2,
        ]))->getStatusCode());
        $this->assertSame(403, $controller->destinations($this->request('GET', []))->getStatusCode());
        $this->assertSame(0, DB::table('school_promotion_previews')->count());
        $this->assertSame(2, DB::table('student_enrollments')->count());
    }

    public function test_year_order_uses_real_school_start_dates_not_database_ids(): void
    {
        DB::table('academic_years')->insert([
            ['id' => 50, 'school_id' => 1, 'starts_on' => '2027-09-01'],
            ['id' => 40, 'school_id' => 1, 'starts_on' => '2028-09-01'],
        ]);
        DB::table('sections')->insert([
            ['id' => 50, 'grade_id' => 1, 'academic_year_id' => 50, 'capacity' => 30],
            ['id' => 40, 'grade_id' => 2, 'academic_year_id' => 40, 'capacity' => 30],
        ]);
        DB::table('children')->insert(['id' => 50, 'name' => 'Later year student', 'organization_id' => 1]);
        DB::table('student_enrollments')->insert([
            'id' => 50, 'section_id' => 50, 'child_id' => 50,
            'status' => 'active', 'enrolled_on' => '2027-09-01',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $controller = app(SchoolAnnualPromotionController::class);
        $roster = $controller->roster($this->request('GET', [
            'source_year_id' => 50, 'target_year_id' => 40,
        ]))->getData(true);
        $this->assertTrue($roster['complete']);
        $this->assertCount(1, $roster['students']);
        $payload = [
            'source_year_id' => 50, 'target_year_id' => 40,
            'roster_revision' => $roster['revision'],
            'decisions' => [['enrollment_id' => 50, 'decision' => 'promoted', 'target_section_id' => 40]],
        ];
        $preview = $controller->preview($this->request('POST', $payload))->getData(true);
        $this->assertTrue($preview['ready']);
        $approved = $controller->approve($this->request('POST', [
            ...$payload, 'preview_token' => $preview['preview_token'],
            'idempotency_key' => 'reversed_year_order_01',
        ]));
        $this->assertSame(200, $approved->getStatusCode());
        $this->assertDatabaseHas('student_enrollments', [
            'section_id' => 40, 'child_id' => 50, 'status' => 'active',
        ]);
    }

    public function test_standalone_school_promotion_preserves_old_enrollments(): void
    {
        DB::table('schools')->insert(['id' => 3, 'organization_id' => null, 'is_active' => true]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 3, 'user_id' => 30, 'role' => 'director',
        ]);
        DB::table('grades')->insert([
            ['id' => 30, 'school_id' => 3, 'position' => 1],
            ['id' => 31, 'school_id' => 3, 'position' => 2],
        ]);
        DB::table('academic_years')->insert([
            ['id' => 30, 'school_id' => 3, 'starts_on' => '2025-09-01'],
            ['id' => 31, 'school_id' => 3, 'starts_on' => '2026-09-01'],
        ]);
        DB::table('sections')->insert([
            ['id' => 30, 'grade_id' => 30, 'academic_year_id' => 30, 'capacity' => 2],
            ['id' => 31, 'grade_id' => 31, 'academic_year_id' => 31, 'capacity' => 2],
        ]);
        DB::table('children')->insert([
            'id' => 30, 'name' => 'Independent pupil', 'organization_id' => null,
        ]);
        DB::table('student_enrollments')->insert([
            'id' => 30, 'section_id' => 30, 'child_id' => 30,
            'status' => 'active', 'enrolled_on' => '2025-09-01',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $controller = app(SchoolAnnualPromotionController::class);
        $roster = $controller->roster($this->request('GET', [
            'source_year_id' => 30, 'target_year_id' => 31,
        ], 30))->getData(true);
        $this->assertSame(3, $roster['school_id']);
        $this->assertCount(1, $roster['students']);
        $draft = ['source_year_id' => 30, 'target_year_id' => 31,
            'roster_revision' => $roster['revision'], 'decisions' => [
                ['enrollment_id' => 30, 'decision' => 'promoted', 'target_section_id' => 31],
            ],
        ];
        $preview = $controller->preview($this->request('POST', $draft, 30))->getData(true);
        $this->assertTrue($preview['ready']);
        $approval = $controller->approve($this->request('POST', [
            ...$draft, 'preview_token' => $preview['preview_token'],
            'idempotency_key' => 'independent_promotion_30',
        ], 30));
        $this->assertSame(200, $approval->getStatusCode());
        $this->assertDatabaseHas('student_enrollments', [
            'id' => 30, 'child_id' => 30, 'status' => 'transferred',
        ]);
        $this->assertDatabaseHas('student_enrollments', [
            'section_id' => 31, 'child_id' => 30, 'status' => 'active',
        ]);
    }

    public function test_replacing_director_keeps_school_history_but_revokes_former_director(): void
    {
        $draft = $this->draft();
        $preview = $this->preview($draft);
        $controller = app(SchoolAnnualPromotionController::class);
        $approval = $controller->approve($this->request('POST', [
            ...$draft, 'preview_token' => $preview['preview_token'],
            'idempotency_key' => 'director_rotation_123',
        ]));
        $this->assertSame(200, $approval->getStatusCode());
        DB::table('school_management_assignments')->where('school_id', 1)
            ->where('user_id', 10)->update(['ends_at' => now()]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 1, 'user_id' => 11, 'role' => 'director',
        ]);
        $this->assertSame(403, $controller->history($this->request('GET', [
            'year_id' => 1,
        ], 10))->getStatusCode());
        $history = $controller->history($this->request('GET', [
            'year_id' => 1,
        ], 11))->getData(true);
        $this->assertCount(1, $history['operations']);
        $this->assertSame('director_rotation_123', $history['operations'][0]['operation_id']);
        $this->assertSame(403, $controller->operation(
            $this->request('GET', [], 10), 'director_rotation_123',
        )->getStatusCode());
        $this->assertSame(200, $controller->operation(
            $this->request('GET', [], 11), 'director_rotation_123',
        )->getStatusCode());
    }

    public function test_school_operation_dispatcher_rejects_legacy_promotion_bypass(): void
    {
        $dispatcher = app(\App\Http\Controllers\SchoolOperationsController::class);
        foreach (['promotion-preview', 'promotion-approve'] as $action) {
            $this->assertSame(404, $dispatcher->handle(
                $this->request('POST', ['expected_school_id' => 1]), $action,
            )->getStatusCode(), $action);
        }
    }

}
