<?php

namespace Tests\Feature;

use App\Http\Controllers\EmergencyAlertController;
use App\Http\Controllers\EngagementController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class EmergencyEngagementAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email');
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

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('title')->nullable();
            $table->text('message');
            $table->string('type')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('emergency_alerts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('triggered_by')->nullable();
            $table->string('status', 20)->default('active');
            $table->text('message')->nullable();
            $table->string('source', 20)->default('app');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
        });

        Schema::create('child_rewards', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id')->primary();
            $table->unsignedInteger('stars')->default(0);
            $table->timestamps();
        });

        Schema::create('game_attempts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('game_key', 80);
            $table->unsignedTinyInteger('score');
            $table->unsignedTinyInteger('stars_earned')->default(0);
            $table->unsignedInteger('duration_seconds')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'ولي الأمر', 'email' => 'parent@example.com', 'role' => 'parent'],
            ['id' => 2, 'name' => 'المختص', 'email' => 'specialist@example.com', 'role' => 'specialist'],
            ['id' => 3, 'name' => 'ولي أمر ثانٍ', 'email' => 'parent2@example.com', 'role' => 'parent'],
            ['id' => 4, 'name' => 'الوزارة', 'email' => 'ministry@example.com', 'role' => 'ministry'],
        ]);

        DB::table('children')->insert([
            'id' => 10,
            'name' => 'أحمد',
            'assigned_teacher_id' => null,
        ]);

        DB::table('child_parent')->insert([
            ['child_id' => 10, 'parent_id' => 1],
            ['child_id' => 10, 'parent_id' => 3],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 10,
            'specialist_id' => 2,
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('game_attempts');
        Schema::dropIfExists('child_rewards');
        Schema::dropIfExists('emergency_alerts');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_game_stars_are_derived_from_score_and_not_client_input(): void
    {
        $controller = app(EngagementController::class);
        $response = $controller->storeAttempt(
            $this->request('POST', [
                'game_key' => 'advanced_reading',
                'score' => 90,
                'stars_earned' => 10,
                'duration_seconds' => 45,
            ], 1, 'parent'),
            10
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('game_attempts', [
            'child_id' => 10,
            'game_key' => 'advanced_reading',
            'score' => 90,
            'stars_earned' => 3,
        ]);
        $this->assertDatabaseHas('child_rewards', [
            'child_id' => 10,
            'stars' => 3,
        ]);

        $payload = json_decode($response->getContent(), true);
        $this->assertSame(3, $payload['stars']);
    }

    public function test_ministry_cannot_write_engagement_data(): void
    {
        $response = app(EngagementController::class)->storeAttempt(
            $this->request('POST', [
                'game_key' => 'matching',
                'score' => 100,
            ], 4, 'ministry'),
            10
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseCount('game_attempts', 0);
        $this->assertDatabaseCount('child_rewards', 0);
    }

    public function test_emergency_alert_notifies_other_parents_and_specialists(): void
    {
        $response = app(EmergencyAlertController::class)->store(
            $this->request('POST', [
                'source' => 'app',
                'message' => 'تنبيه اختبار',
            ], 1, 'parent'),
            10
        );

        $this->assertSame(201, $response->getStatusCode());
        $payload = json_decode($response->getContent(), true);

        $this->assertSame(2, $payload['intended_recipients']);
        $this->assertSame(2, $payload['notified_recipients']);
        $this->assertDatabaseCount('emergency_alerts', 1);
        $this->assertDatabaseHas('notifications', [
            'user_id' => 2,
            'type' => 'emergency',
        ]);
        $this->assertDatabaseHas('notifications', [
            'user_id' => 3,
            'type' => 'emergency',
        ]);
        $this->assertDatabaseMissing('notifications', [
            'user_id' => 1,
            'type' => 'emergency',
        ]);
    }

    public function test_ministry_cannot_trigger_emergency_alert(): void
    {
        $response = app(EmergencyAlertController::class)->store(
            $this->request('POST', ['source' => 'web'], 4, 'ministry'),
            10
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseCount('emergency_alerts', 0);
        $this->assertDatabaseCount('notifications', 0);
    }

    private function request(
        string $method,
        array $payload,
        int $id,
        string $role
    ): Request {
        $request = Request::create('/api/test', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set(
            'jwt_user',
            (object) ['id' => $id, 'role' => $role]
        );

        return $request;
    }
}
