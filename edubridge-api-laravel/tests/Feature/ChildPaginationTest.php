<?php

namespace Tests\Feature;

use App\Http\Controllers\ChildController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class ChildPaginationTest extends TestCase
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
        Schema::table('children', fn (Blueprint $table) => $table->string('disability_type')->nullable());
        Schema::create('progress', function (Blueprint $table) {
            $table->id(); $table->integer('child_id'); $table->string('status');
        });
        foreach (range(20, 59) as $id) {
            DB::table('children')->insert(['id' => $id, 'name' => $id === 59 ? 'Far away result 100%' : 'Same name', 'status' => $id % 2 ? 'assigned' : 'pending']);
            DB::table('child_parent')->insert(['child_id' => $id, 'parent_id' => $id % 2 ? 1 : 99]);
        }
        DB::table('progress')->insert([['child_id' => 21, 'status' => 'done'], ['child_id' => 20, 'status' => 'done']]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('progress');
        Schema::dropIfExists('ministry_approvals');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('children');
        Schema::dropIfExists('disability_types');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    private function page(string $role, int $id, array $params): array
    {
        $request = Request::create('/api/children', 'GET', $params);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        $response = app(ChildController::class)->index($request);
        $this->assertSame(200, $response->getStatusCode());
        return $response->getData(true);
    }

    public function test_parent_pages_and_totals_are_scoped_and_global_stats_survive_filters(): void
    {
        $first = $this->page('parent', 1, ['page' => 1, 'per_page' => 3]);
        $this->assertCount(3, $first['children']);
        $this->assertSame(21, $first['pagination']['total']);
        $this->assertSame(['total_children' => 21, 'active_plans' => 20, 'completed_tasks' => 1], $first['summary']);
        $search = $this->page('parent', 1, ['page' => 1, 'q' => '100%']);
        $this->assertSame([59], array_column($search['children'], 'id'));
        $this->assertSame(1, $search['pagination']['total']);
        $this->assertSame($first['summary'], $search['summary']);
        $none = $this->page('parent', 99, ['page' => 1, 'q' => '100%']);
        $this->assertSame(0, $none['pagination']['total']);
    }

    public function test_tied_names_are_stable_and_later_pages_are_not_silently_lost(): void
    {
        $ids = [];
        for ($page = 1; $page <= 6; $page++) {
            $data = $this->page('admin', 3, ['page' => $page, 'per_page' => 7]);
            $ids = array_merge($ids, array_column($data['children'], 'id'));
        }
        $this->assertCount(41, $ids);
        $this->assertCount(41, array_unique($ids));
        $this->assertSame(41, $this->page('admin', 3, ['page' => 99])['pagination']['total']);
        $this->assertSame([], $this->page('admin', 3, ['page' => 99])['children']);
    }

    public function test_teacher_team_and_specialist_filters_preserve_private_summary_rules(): void
    {
        DB::table('child_teacher')->insert(['child_id' => 21, 'teacher_id' => 2]);
        $teacher = $this->page('teacher', 2, ['page' => 1]);
        $this->assertSame([21, 10], array_column($teacher['children'], 'id'));
        DB::table('child_specialist')->insert(['child_id' => 21, 'specialist_id' => 99]);
        $specialist = $this->page('specialist', 99, ['page' => 1, 'assigned_only' => 1]);
        $this->assertSame([21], array_column($specialist['children'], 'id'));
        $discovery = $this->page('specialist', 99, ['page' => 1, 'q' => 'طفل']);
        $this->assertArrayNotHasKey('strengths', $discovery['children'][0]);
        $this->assertArrayNotHasKey('guardian_national_id', $discovery['children'][0]);
        $this->assertSame(0, $this->page('institution', 90, ['page' => 1])['pagination']['total']);
    }

    public function test_invalid_page_parameters_raise_validation_errors(): void
    {
        foreach ([['page' => 0], ['page' => 'bad'], ['per_page' => 101], ['page' => 1, 'q' => ['bad']], ['page' => 1, 'active_only' => 'bad']] as $params) {
            try { $this->page('admin', 3, $params); $this->fail('Invalid page accepted'); }
            catch (ValidationException $e) { $this->assertSame(422, $e->status); }
        }
    }
}
