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

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
            $table->string('specialty')->nullable();
            $table->timestamp('assigned_at')->nullable();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'ولي الأمر', 'role' => 'parent'],
            ['id' => 2, 'name' => 'المعلم', 'role' => 'teacher'],
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
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_parent');
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

    private function request(int $id, string $role): Request
    {
        $request = Request::create('/api/children', 'GET');
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
