<?php

namespace Tests\Feature;

use App\Http\Controllers\EngagementController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

class EngagementIdempotencyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', fn (Blueprint $table) => $table->id());
        Schema::create('children', fn (Blueprint $table) => $table->id());
        Schema::create('child_rewards', function (Blueprint $table) {
            $table->integer('child_id')->primary(); $table->integer('stars'); $table->timestamps();
        });
        Schema::create('game_attempts', function (Blueprint $table) {
            $table->id(); $table->integer('child_id'); $table->integer('user_id'); $table->string('game_key');
            $table->integer('score'); $table->integer('stars_earned'); $table->integer('duration_seconds')->nullable(); $table->timestamp('created_at');
        });
        (require database_path('migrations/2026_10_02_000001_create_engagement_events_table.php'))->up();
        DB::table('users')->insert(['id' => 1]); DB::table('children')->insert(['id' => 10]);
    }

    protected function tearDown(): void
    {
        foreach (['engagement_events', 'game_attempts', 'child_rewards', 'children', 'users'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function request(array $payload): Request
    {
        $request = Request::create('/api/children/10/game-attempts', 'POST', $payload);
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'admin']);
        return $request;
    }

    public function test_replayed_game_attempt_returns_original_receipt_without_duplicate_stars(): void
    {
        $request = $this->request(['event_id' => '11111111-1111-4111-8111-111111111111', 'game_key' => 'colors', 'score' => 95]);
        $controller = app(EngagementController::class);
        $first = $controller->storeAttempt($request, 10);
        $second = $controller->storeAttempt($request, 10);
        $this->assertSame($first->getContent(), $second->getContent());
        $this->assertDatabaseCount('game_attempts', 1);
        $this->assertDatabaseHas('child_rewards', ['child_id' => 10, 'stars' => 3]);
        $this->assertDatabaseCount('engagement_events', 1);
    }

    public function test_star_batches_are_idempotent_and_distinct_events_still_accumulate(): void
    {
        $controller = app(EngagementController::class);
        $request = $this->request(['event_id' => '11111111-1111-4111-8111-111111111111', 'count' => 20]);
        $controller->addStars($request, 10); $controller->addStars($request, 10);
        $controller->addStars($this->request(['event_id' => '22222222-2222-4222-8222-222222222222', 'count' => 5]), 10);
        $this->assertDatabaseHas('child_rewards', ['stars' => 25]);
        $this->assertDatabaseCount('engagement_events', 2);
    }

    public function test_reusing_event_id_for_another_payload_or_endpoint_is_rejected(): void
    {
        $controller = app(EngagementController::class);
        $id = '11111111-1111-4111-8111-111111111111';
        $controller->addStars($this->request(['event_id' => $id, 'count' => 1]), 10);
        foreach ([['count' => 2], ['game_key' => 'colors', 'score' => 90]] as $payload) {
            try {
                $request = $this->request(['event_id' => $id] + $payload);
                isset($payload['count']) ? $controller->addStars($request, 10) : $controller->storeAttempt($request, 10);
                $this->fail('Expected conflict');
            } catch (HttpException $e) { $this->assertSame(409, $e->getStatusCode()); }
        }
        $this->assertDatabaseHas('child_rewards', ['stars' => 1]);
        $this->assertDatabaseCount('game_attempts', 0);
    }
}
