<?php

namespace Tests\Feature;

use App\Http\Controllers\ConsultationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ConsultationControllerAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('role');
        });

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('consultations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('requester_id');
            $table->unsignedBigInteger('specialist_id')->nullable();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status')->default('open');
            $table->timestamps();
        });

        Schema::create('consultation_notes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('consultation_id');
            $table->unsignedBigInteger('author_id');
            $table->text('content');
            $table->timestamps();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'ولي 1', 'role' => 'parent'],
            ['id' => 2, 'name' => 'ولي 2', 'role' => 'parent'],
            ['id' => 3, 'name' => 'معلم', 'role' => 'teacher'],
            ['id' => 4, 'name' => 'مختص 1', 'role' => 'specialist'],
            ['id' => 5, 'name' => 'مختص 2', 'role' => 'specialist'],
            ['id' => 6, 'name' => 'أدمن', 'role' => 'admin'],
        ]);

        DB::table('children')->insert([
            ['id' => 10, 'name' => 'طفل أ', 'assigned_teacher_id' => 3],
            ['id' => 20, 'name' => 'طفل ب', 'assigned_teacher_id' => null],
        ]);

        DB::table('child_parent')->insert([
            ['child_id' => 10, 'parent_id' => 1],
            ['child_id' => 20, 'parent_id' => 2],
        ]);

        DB::table('consultations')->insert([
            [
                'id' => 100,
                'child_id' => 10,
                'requester_id' => 1,
                'specialist_id' => null,
                'title' => 'حالة مفتوحة',
                'status' => 'open',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 200,
                'child_id' => 10,
                'requester_id' => 1,
                'specialist_id' => 4,
                'title' => 'حالة مسندة',
                'status' => 'in_progress',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('consultation_notes');
        Schema::dropIfExists('consultations');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_parent_cannot_create_consultation_for_another_child(): void
    {
        $response = app(ConsultationController::class)->store(
            $this->request('POST', [
                'child_id' => 20,
                'title' => 'طلب غير مصرح',
            ], 1, 'parent')
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('consultations', ['title' => 'طلب غير مصرح']);
    }

    public function test_assigned_teacher_can_create_consultation_for_their_child(): void
    {
        $response = app(ConsultationController::class)->store(
            $this->request('POST', [
                'child_id' => 10,
                'title' => 'طلب المعلم',
            ], 3, 'teacher')
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('consultations', [
            'child_id' => 10,
            'requester_id' => 3,
            'title' => 'طلب المعلم',
        ]);
    }

    public function test_specialist_cannot_claim_consultation_assigned_to_another_specialist(): void
    {
        $response = app(ConsultationController::class)->update(
            $this->request('PUT', ['claim' => true], 5, 'specialist'),
            200
        );

        $this->assertSame(409, $response->getStatusCode());
        $this->assertDatabaseHas('consultations', [
            'id' => 200,
            'specialist_id' => 4,
        ]);
    }

    public function test_specialist_can_claim_open_unassigned_consultation(): void
    {
        $response = app(ConsultationController::class)->update(
            $this->request('PUT', ['claim' => true], 5, 'specialist'),
            100
        );

        $this->assertSame(200, $response->getStatusCode());
        $this->assertDatabaseHas('consultations', [
            'id' => 100,
            'specialist_id' => 5,
            'status' => 'in_progress',
        ]);
    }

    public function test_unassigned_specialist_cannot_add_note(): void
    {
        $response = app(ConsultationController::class)->addNote(
            $this->request('POST', ['content' => 'غير مسموح'], 5, 'specialist'),
            200
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('consultation_notes', [
            'consultation_id' => 200,
            'author_id' => 5,
        ]);
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/consultations', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
