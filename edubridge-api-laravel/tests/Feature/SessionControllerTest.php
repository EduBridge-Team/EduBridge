<?php

namespace Tests\Feature;

use App\Http\Controllers\SessionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SessionControllerTest extends TestCase
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

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('specialist_id')->nullable();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('learning_support_request_id')->nullable();
            $table->string('type')->default('followUp');
            $table->timestamp('scheduled_at')->nullable();
            $table->integer('duration_minutes')->default(45);
            $table->text('goals')->nullable();
            $table->text('meeting_link')->nullable();
            $table->string('status')->default('scheduled');
            $table->text('notes')->nullable();
            $table->text('recommendations')->nullable();
            $table->integer('mood_rating')->nullable();
            $table->text('tags')->nullable();
            $table->timestamp('completed_at')->nullable();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'معلم 1', 'role' => 'teacher'],
            ['id' => 2, 'name' => 'معلم 2', 'role' => 'teacher'],
            ['id' => 3, 'name' => 'مختص', 'role' => 'specialist'],
            ['id' => 4, 'name' => 'مختص آخر', 'role' => 'specialist'],
            ['id' => 5, 'name' => 'أدمن', 'role' => 'admin'],
        ]);

        DB::table('children')->insert([
            ['id' => 10, 'name' => 'طفل أ', 'assigned_teacher_id' => 1],
            ['id' => 20, 'name' => 'طفل ب', 'assigned_teacher_id' => 2],
            ['id' => 30, 'name' => 'طفل ج', 'assigned_teacher_id' => null],
        ]);

        DB::table('child_teacher')->insert([
            'child_id' => 30,
            'teacher_id' => 1,
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 10,
            'specialist_id' => 3,
        ]);

        DB::table('sessions')->insert([
            [
                'id' => 100,
                'specialist_id' => 3,
                'child_id' => 10,
                'type' => 'followUp',
                'scheduled_at' => now()->addDay(),
                'duration_minutes' => 45,
                'status' => 'scheduled',
            ],
            [
                'id' => 200,
                'specialist_id' => 4,
                'child_id' => 20,
                'type' => 'followUp',
                'scheduled_at' => now()->addDays(2),
                'duration_minutes' => 45,
                'status' => 'scheduled',
            ],
            [
                'id' => 300,
                'specialist_id' => 4,
                'child_id' => 30,
                'type' => 'followUp',
                'scheduled_at' => now()->addDays(3),
                'duration_minutes' => 45,
                'status' => 'scheduled',
            ],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_teacher_only_sees_sessions_for_assigned_children(): void
    {
        $response = app(SessionController::class)->index(
            $this->request('GET', [], 1, 'teacher')
        );

        $this->assertSame(200, $response->getStatusCode());
        $sessions = json_decode($response->getContent(), true)['sessions'];
        $ids = array_column($sessions, 'id');
        sort($ids);

        $this->assertSame([100, 300], $ids);
    }

    public function test_teacher_cannot_filter_sessions_for_unassigned_child(): void
    {
        $request = $this->request('GET', [], 1, 'teacher');
        $request->query->set('child_id', 20);

        $response = app(SessionController::class)->index($request);

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_specialist_can_only_create_session_for_child_in_their_team(): void
    {
        $controller = app(SessionController::class);

        $blocked = $controller->store($this->request('POST', [
            'child_id' => 20,
            'scheduled_at' => now()->addDay()->toIso8601String(),
            'type' => 'followUp',
        ], 3, 'specialist'));

        $this->assertSame(403, $blocked->getStatusCode());

        $allowed = $controller->store($this->request('POST', [
            'child_id' => 10,
            'scheduled_at' => now()->addDay()->toIso8601String(),
            'type' => 'followUp',
        ], 3, 'specialist'));

        $this->assertSame(201, $allowed->getStatusCode());
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/sessions', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
