<?php

namespace Tests\Feature;

use App\Http\Controllers\LessonRecommendationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class LessonRecommendationTest extends TestCase
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
            $table->unsignedBigInteger('disability_type_id')->nullable();
        });
        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->unsignedBigInteger('teacher_id')->nullable();
            $table->string('target_type')->nullable();
            $table->text('target_child_ids')->nullable();
            $table->unsignedBigInteger('disability_type_id')->nullable();
        });
        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });
        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('title');
            $table->string('message');
            $table->string('type')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('created_at')->useCurrent();
        });

        DB::table('users')->insert([
            ['id' => 3, 'name' => 'المختص', 'role' => 'specialist'],
            ['id' => 8, 'name' => 'ولي الأمر', 'role' => 'parent'],
        ]);
        DB::table('children')->insert([
            ['id' => 10, 'name' => 'الطفل الأول', 'disability_type_id' => 2],
            ['id' => 20, 'name' => 'طفل آخر', 'disability_type_id' => 3],
        ]);
        DB::table('child_specialist')->insert(['child_id' => 10, 'specialist_id' => 3]);
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 8]);
        DB::table('lessons')->insert([
            ['id' => 4, 'title' => 'درس مشترك', 'teacher_id' => 3,
             'target_type' => 'everyone', 'target_child_ids' => null,
             'disability_type_id' => null],
            ['id' => 5, 'title' => 'درس خاص', 'teacher_id' => 3,
             'target_type' => 'specificChildren', 'target_child_ids' => json_encode([20]),
             'disability_type_id' => null],
            ['id' => 6, 'title' => 'درس لإعاقة أخرى', 'teacher_id' => 3,
             'target_type' => 'byDisability', 'target_child_ids' => null,
             'disability_type_id' => 3],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['notifications', 'child_parent', 'child_specialist', 'lessons', 'children', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function recommend(int $lessonId, int $childId, string $role = 'specialist')
    {
        $request = Request::create('/api/lessons/' . $lessonId . '/recommend', 'POST', [
            'child_id' => $childId,
        ]);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => 3, 'role' => $role]);
        return app(LessonRecommendationController::class)->store($request, $lessonId);
    }

    public function test_assigned_specialist_notifies_parent_and_deduplicates_within_one_day(): void
    {
        $response = $this->recommend(4, 10);
        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('notifications', [
            'user_id' => 8,
            'type' => 'lesson_recommendation',
        ]);

        $response = $this->recommend(4, 10);
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame(1, DB::table('notifications')->count());
    }

    public function test_unassigned_child_cannot_receive_recommendation(): void
    {
        $this->assertSame(403, $this->recommend(4, 20)->getStatusCode());
        $this->assertSame(0, DB::table('notifications')->count());
    }

    public function test_only_specialists_can_recommend(): void
    {
        $this->assertSame(403, $this->recommend(4, 10, 'parent')->getStatusCode());
        $this->assertSame(0, DB::table('notifications')->count());
    }

    public function test_nonvisible_private_lesson_is_not_recommended(): void
    {
        $this->assertSame(422, $this->recommend(5, 10)->getStatusCode());
        $this->assertSame(0, DB::table('notifications')->count());
    }

    public function test_unmatched_disability_does_not_receive_recommendation(): void
    {
        $this->assertSame(422, $this->recommend(6, 10)->getStatusCode());
        $this->assertSame(0, DB::table('notifications')->count());
    }

    public function test_no_linked_parent_returns_actionable_error(): void
    {
        DB::table('child_parent')->delete();
        $this->assertSame(422, $this->recommend(4, 10)->getStatusCode());
        $this->assertSame(0, DB::table('notifications')->count());
    }
}
