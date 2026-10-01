<?php

namespace Tests\Feature;

use App\Http\Controllers\RatingController;
use App\Services\RatingCommentPolicy;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class LessonRatingsTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
        });
        Schema::create('lessons', fn (Blueprint $table) => $table->id());
        Schema::create('lesson_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');
            $table->unsignedBigInteger('user_id');
            $table->integer('stars');
            $table->text('comment')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['lesson_id', 'user_id']);
        });
        DB::table('users')->insert(['id' => 1, 'name' => 'ولي أمر']);
        DB::table('lessons')->insert(['id' => 1]);
    }

    protected function tearDown(): void
    {
        foreach (['lesson_ratings', 'lessons', 'users'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    public function test_repeated_rating_updates_one_row_and_average(): void
    {
        $controller = app(RatingController::class);
        $controller->store($this->request(['stars' => 2]), 1);
        $response = $controller->store($this->request(['stars' => 5, 'comment' => '  درس مفيد  ']), 1);
        $this->assertSame(201, $response->getStatusCode());
        $this->assertSame(1, DB::table('lesson_ratings')->count());
        $this->assertSame('درس مفيد', DB::table('lesson_ratings')->first()->comment);
        $summary = $controller->index($this->request(), 1)->getData(true);
        $this->assertSame(1, $summary['count']);
        $this->assertEquals(5, $summary['average']);
        $this->assertSame(5, $summary['my_rating']['stars']);
    }

    public function test_fractional_stars_are_rejected(): void
    {
        $this->expectException(ValidationException::class);
        app(RatingController::class)->store($this->request(['stars' => 2.5]), 1);
    }

    public function test_non_text_comment_is_rejected(): void
    {
        $this->expectException(ValidationException::class);
        app(RatingController::class)->store($this->request(['stars' => 3, 'comment' => ['spam']]), 1);
    }

    public function test_abusive_comment_is_rejected_without_overwriting_rating(): void
    {
        $controller = app(RatingController::class);
        $controller->store($this->request(['stars' => 4, 'comment' => 'شرح جيد']), 1);
        $response = $controller->store($this->request(['stars' => 1, 'comment' => 'FUCK!']), 1);
        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame(4, DB::table('lesson_ratings')->first()->stars);
    }

    public function test_moderation_ignores_arabic_marks_and_preserves_valid_substrings(): void
    {
        config(['ratings.blocked_words' => ['إساءة', 'bad']]);
        $this->assertTrue(RatingCommentPolicy::isAbusive('إِسَـاءة!'));
        $this->assertFalse(RatingCommentPolicy::isAbusive('badminton درس مفيد'));
    }

    public function test_only_owner_or_admin_can_remove_rating(): void
    {
        $controller = app(RatingController::class);
        $id = $controller->store($this->request(['stars' => 4]), 1)->getData(true)['rating']['id'];
        $this->assertSame(403, $controller->destroy($this->request([], 2), $id)->getStatusCode());
        $admin = $this->request([], 2);
        $admin->attributes->set('jwt_user', (object) ['id' => 2, 'role' => 'admin']);
        $this->assertSame(200, $controller->destroy($admin, $id)->getStatusCode());
        $this->assertSame(0, DB::table('lesson_ratings')->count());
    }

    private function request(array $payload = [], int $userId = 1): Request
    {
        $request = Request::create('/api/lessons/1/ratings', 'POST', $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $userId, 'role' => 'parent']);
        return $request;
    }
}
