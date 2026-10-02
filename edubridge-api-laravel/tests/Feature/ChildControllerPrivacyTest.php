<?php

namespace Tests\Feature;

use App\Http\Controllers\ChildController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildControllerPrivacyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('role');
        });

        Schema::create('disability_types', function (Blueprint $table) {
            $table->id();
            $table->string('name');
        });

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
            $table->unsignedBigInteger('disability_type_id')->nullable();
            $table->unsignedBigInteger('organization_id')->nullable();
            $table->string('status')->default('pending');
            $table->string('doc_verification_status')->default('verified');
            $table->string('child_national_id')->nullable();
            $table->string('guardian_national_id')->nullable();
            $table->text('guardian_id_document_url')->nullable();
            $table->text('kinship_document_url')->nullable();
            $table->text('strengths')->nullable();
            $table->text('challenges')->nullable();
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });
        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id'); $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
            $table->string('specialty')->nullable();
            $table->timestamp('assigned_at')->nullable();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'ولي الأمر', 'role' => 'parent'],
            ['id' => 2, 'name' => 'المعلم', 'role' => 'teacher'],
            ['id' => 3, 'name' => 'الأدمن', 'role' => 'admin'],
        ]);

        DB::table('children')->insert([
            'id' => 10,
            'name' => 'طفل',
            'assigned_teacher_id' => 2,
            'child_national_id' => '123456789',
            'guardian_national_id' => '987654321',
            'guardian_id_document_url' => '/api/private-files/user/1/id.jpg',
            'kinship_document_url' => '/api/private-files/user/1/kinship.pdf',
            'strengths' => json_encode(['القراءة'], JSON_UNESCAPED_UNICODE),
            'challenges' => json_encode(['التركيز'], JSON_UNESCAPED_UNICODE),
        ]);

        DB::table('child_parent')->insert([
            'child_id' => 10,
            'parent_id' => 1,
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('ministry_approvals');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('children');
        Schema::dropIfExists('disability_types');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_teacher_child_list_hides_identity_fields(): void
    {
        $response = app(ChildController::class)->index(
            $this->request(2, 'teacher')
        );

        $this->assertSame(200, $response->getStatusCode());
        $child = json_decode($response->getContent(), true)['children'][0];

        $this->assertArrayNotHasKey('child_national_id', $child);
        $this->assertArrayNotHasKey('guardian_national_id', $child);
        $this->assertArrayNotHasKey('guardian_id_document_url', $child);
        $this->assertArrayNotHasKey('kinship_document_url', $child);
        $this->assertSame(['القراءة'], $child['strengths']);
    }

    public function test_teacher_directory_excludes_unrelated_children_and_includes_team_assignments(): void
    {
        DB::table('children')->insert(['id' => 20, 'name' => 'Unrelated']);
        DB::table('children')->insert(['id' => 30, 'name' => 'Team child']);
        DB::table('child_teacher')->insert(['child_id' => 30, 'teacher_id' => 2]);
        $data = app(ChildController::class)->index($this->request(2, 'teacher'))->getData(true);
        $this->assertEqualsCanonicalizing([10, 30], array_column($data['children'], 'id'));
        $institution = app(ChildController::class)->index($this->request(4, 'institution'))->getData(true);
        $this->assertSame([], $institution['children']);
    }

    public function test_parent_child_list_keeps_identity_fields_for_own_child(): void
    {
        $response = app(ChildController::class)->index(
            $this->request(1, 'parent')
        );

        $this->assertSame(200, $response->getStatusCode());
        $child = json_decode($response->getContent(), true)['children'][0];

        $this->assertSame('123456789', $child['child_national_id']);
        $this->assertSame('987654321', $child['guardian_national_id']);
        $this->assertSame('/api/private-files/user/1/id.jpg', $child['guardian_id_document_url']);
        $this->assertSame('/api/private-files/user/1/kinship.pdf', $child['kinship_document_url']);
    }

    public function test_teacher_update_response_does_not_leak_identity_fields(): void
    {
        $response = app(ChildController::class)->update(
            $this->request(2, 'teacher', 'PUT', ['name' => 'اسم محدث']),
            10
        );

        $this->assertSame(200, $response->getStatusCode());
        $child = json_decode($response->getContent(), true)['child'];

        $this->assertSame('اسم محدث', $child['name']);
        $this->assertArrayNotHasKey('child_national_id', $child);
        $this->assertArrayNotHasKey('guardian_national_id', $child);
        $this->assertArrayNotHasKey('guardian_id_document_url', $child);
        $this->assertArrayNotHasKey('kinship_document_url', $child);
    }

    public function test_teacher_cannot_modify_identity_fields(): void
    {
        $response = app(ChildController::class)->update(
            $this->request(2, 'teacher', 'PUT', ['guardian_national_id' => '111111111']),
            10
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseHas('children', [
            'id' => 10,
            'guardian_national_id' => '987654321',
        ]);
    }

    public function test_parent_cannot_modify_admin_only_fields(): void
    {
        $response = app(ChildController::class)->update(
            $this->request(1, 'parent', 'PUT', ['status' => 'assigned']),
            10
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseHas('children', [
            'id' => 10,
            'status' => 'pending',
        ]);
    }

    public function test_admin_teacher_assignment_requires_teacher_account(): void
    {
        $response = app(ChildController::class)->update(
            $this->request(3, 'admin', 'PUT', ['assigned_teacher_id' => 3]),
            10
        );

        $this->assertSame(422, $response->getStatusCode());
        $this->assertDatabaseHas('children', [
            'id' => 10,
            'assigned_teacher_id' => 2,
        ]);
    }

    public function test_unassigned_specialist_cannot_edit_child_fields(): void
    {
        $response = app(ChildController::class)->update(
            $this->request(99, 'specialist', 'PUT', ['name' => 'تغيير غير مصرّح']), 10
        );
        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('children', ['id' => 10, 'name' => 'تغيير غير مصرّح']);
    }

    private function createPlans(): void
    {
        Schema::create('ministry_approvals', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->string('status');
            $table->text('educational_plan')->nullable();
            $table->text('teaching_methods')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('created_at')->nullable();
        });
        DB::table('ministry_approvals')->insert([
            ['id' => 1, 'child_id' => 10, 'status' => 'approved', 'educational_plan' => 'Older', 'teaching_methods' => '[]', 'reviewed_at' => '2026-09-01', 'created_at' => '2026-09-01'],
            ['id' => 2, 'child_id' => 10, 'status' => 'approved', 'educational_plan' => 'Current', 'teaching_methods' => '["visual"]', 'reviewed_at' => '2026-09-02', 'created_at' => '2026-09-02'],
            ['id' => 3, 'child_id' => 10, 'status' => 'pending', 'educational_plan' => 'Pending', 'teaching_methods' => '[]', 'reviewed_at' => '2026-09-03', 'created_at' => '2026-09-03'],
        ]);
    }

    public function test_directory_query_count_stays_constant_as_children_increase(): void
    {
        $this->createPlans();
        DB::table('child_specialist')->insert(['child_id' => 10, 'specialist_id' => 2, 'specialty' => 'learning', 'assigned_at' => '2026-09-01']);
        DB::enableQueryLog();
        DB::flushQueryLog();
        $small = app(ChildController::class)->index($this->request(3, 'admin'));
        $smallCount = count(DB::getQueryLog());
        $this->assertSame(200, $small->getStatusCode());
        $this->assertSame(3, $smallCount);
        $child = $small->getData(true)['children'][0];
        $this->assertSame(2, $child['current_plan_id']);
        $this->assertSame(['visual'], $child['current_plan']['teaching_methods']);
        $this->assertSame([2], $child['specialist_ids']);
        $this->assertArrayNotHasKey('child_id', $child['specialists'][0]);
        for ($id = 20; $id < 50; $id++) {
            DB::table('children')->insert(['id' => $id, 'name' => 'Child '.$id]);
        }
        DB::flushQueryLog();
        $large = app(ChildController::class)->index($this->request(3, 'admin'));
        $this->assertSame($smallCount, count(DB::getQueryLog()));
        DB::disableQueryLog();
        $this->assertCount(31, $large->getData(true)['children']);
    }

    public function test_specialist_discovery_never_loads_unassigned_child_plans(): void
    {
        $this->createPlans();
        DB::table('children')->insert(['id' => 20, 'name' => 'Assigned child']);
        DB::table('child_specialist')->insert(['child_id' => 20, 'specialist_id' => 99]);
        DB::enableQueryLog();
        DB::flushQueryLog();
        $response = app(ChildController::class)->index($this->request(99, 'specialist'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();
        $this->assertSame(200, $response->getStatusCode());
        $children = collect($response->getData(true)['children'])->keyBy('id');
        $this->assertArrayNotHasKey('current_plan', $children[10]);
        $this->assertArrayNotHasKey('strengths', $children[10]);
        $this->assertArrayHasKey('current_plan', $children[20]);
        $planQuery = collect($queries)->first(fn ($query) => str_contains($query['query'], 'ranked_plans'));
        $this->assertSame([20, 'approved', 1], $planQuery['bindings']);
    }

    private function request(
        int $id,
        string $role,
        string $method = 'GET',
        array $payload = []
    ): Request {
        $request = Request::create('/api/children', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }

    public function test_parent_cannot_keep_approval_by_sending_status_with_changed_identity(): void
    {
        $response = app(ChildController::class)->update($this->request(1, 'parent', 'PUT', [
            'guardian_national_id' => '111111111', 'doc_verification_status' => 'verified',
        ]), 10);
        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseHas('children', ['id' => 10, 'guardian_national_id' => '987654321', 'doc_verification_status' => 'verified']);
    }

    public function test_unchanged_identity_keeps_approval_and_real_change_requires_review(): void
    {
        $controller = app(ChildController::class);
        $response = $controller->update($this->request(1, 'parent', 'PUT', ['guardian_national_id' => '987654321']), 10);
        $this->assertSame(200, $response->getStatusCode());
        $this->assertDatabaseHas('children', ['id' => 10, 'doc_verification_status' => 'verified']);
        $controller->update($this->request(1, 'parent', 'PUT', ['guardian_national_id' => '111111111']), 10);
        $this->assertDatabaseHas('children', ['id' => 10, 'doc_verification_status' => 'pending']);
    }
}
