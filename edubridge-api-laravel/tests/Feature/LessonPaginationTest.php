<?php

namespace Tests\Feature;

use App\Http\Controllers\LessonController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class LessonPaginationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->integer('assigned_teacher_id')->nullable(); });
        foreach (['child_parent' => 'parent_id', 'child_teacher' => 'teacher_id', 'child_specialist' => 'specialist_id'] as $table => $column) {
            Schema::create($table, function (Blueprint $t) use ($column) { $t->integer('child_id'); $t->integer($column); });
        }
        Schema::create('lessons', function (Blueprint $t) {
            $t->id(); $t->string('title'); $t->text('content')->nullable(); $t->string('category')->nullable();
            $t->integer('teacher_id'); $t->string('target_type'); $t->text('target_child_ids')->nullable();
            $t->timestamp('created_at');
        });
        Schema::create('lesson_ratings', function (Blueprint $t) { $t->id(); $t->integer('lesson_id'); $t->integer('stars'); });
        Schema::create('media', function (Blueprint $t) { $t->id(); $t->integer('lesson_id'); $t->string('type'); $t->string('url'); });
        DB::table('children')->insert([['id' => 1, 'assigned_teacher_id' => 20], ['id' => 2, 'assigned_teacher_id' => 99]]);
        DB::table('child_parent')->insert(['child_id' => 1, 'parent_id' => 10]);
        DB::table('child_teacher')->insert(['child_id' => 1, 'teacher_id' => 21]);
        DB::table('child_specialist')->insert(['child_id' => 1, 'specialist_id' => 30]);
        foreach (range(1, 65) as $id) {
            DB::table('lessons')->insert([
                'id' => $id, 'teacher_id' => 90, 'title' => $id === 1 ? 'Far result 100%' : 'Reading lesson '.$id,
                'content' => 'Content', 'category' => $id % 2 ? 'math' : null,
                'target_type' => $id === 65 ? 'parents' : ($id >= 60 ? 'specificChildren' : 'everyone'),
                'target_child_ids' => json_encode([$id === 64 ? 2 : 1]), 'created_at' => '2026-10-02 12:00:00',
            ]);
            DB::table('media')->insert(['lesson_id' => $id, 'type' => 'image', 'url' => 'https://example.com/image.png']);
        }
        DB::table('lesson_ratings')->insert([['lesson_id' => 1, 'stars' => 4], ['lesson_id' => 1, 'stars' => 2]]);
    }

    protected function tearDown(): void
    {
        foreach (['media', 'lesson_ratings', 'lessons', 'child_parent', 'child_teacher', 'child_specialist', 'children'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function page(string $role, int $id, array $params): array
    {
        $request = Request::create('/api/lessons', 'GET', $params);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        $response = app(LessonController::class)->index($request);
        $this->assertSame(200, $response->getStatusCode());
        return $response->getData(true);
    }

    public function test_lesson_pages_preserve_visibility_and_tied_date_order(): void
    {
        foreach (['parent' => 10, 'teacher' => 20, 'specialist' => 30] as $role => $id) {
            $ids = [];
            for ($page = 1; $page <= 7; $page++) {
                $data = $this->page($role, $id, ['page' => $page, 'per_page' => 10]);
                $ids = array_merge($ids, array_column($data['lessons'], 'id'));
            }
            $expected = array_values(array_filter(range(65, 1), fn ($i) => $i !== 64 && !($role === 'parent' && $i === 65)));
            $this->assertSame($expected, $ids);
        }
        $this->assertSame(64, $this->page('teacher', 21, ['page' => 1])['pagination']['total']);
        $this->assertSame(59, $this->page('parent', 99, ['page' => 1])['pagination']['total']);
        $this->assertSame(65, $this->page('admin', 1, ['page' => 1])['pagination']['total']);
        $this->assertSame(65, $this->page('ministry', 1, ['page' => 1])['pagination']['total']);
    }

    public function test_search_includes_records_beyond_first_page_with_ratings_and_batched_media(): void
    {
        $data = $this->page('parent', 10, ['page' => 1, 'q' => '100%']);
        $this->assertSame([1], array_column($data['lessons'], 'id'));
        $this->assertEquals(3, $data['lessons'][0]['rating_avg']);
        $this->assertSame(2, $data['lessons'][0]['rating_count']);
        $this->assertCount(1, $data['lessons'][0]['media']);
        $this->assertSame(33, $this->page('admin', 1, ['page' => 1, 'category' => 'الرياضيات'])['pagination']['total']);
        $this->assertSame(32, $this->page('admin', 1, ['page' => 1, 'category' => 'غير مصنّف'])['pagination']['total']);
        $this->assertSame(33, $this->page('admin', 1, ['page' => 1, 'q' => 'الرياضيات'])['pagination']['total']);
        $guides = $this->page('parent', 10, ['page' => 1, 'target_type' => 'parents']);
        $this->assertSame([65], array_column($guides['lessons'], 'id'));
    }

    public function test_legacy_lists_remain_complete_and_baseline_without_category_is_truthfully_uncategorized(): void
    {
        $legacy = $this->page('admin', 1, []);
        $this->assertCount(65, $legacy['lessons']);
        $this->assertArrayNotHasKey('pagination', $legacy);
        Schema::table('lessons', fn (Blueprint $t) => $t->dropColumn('category'));
        $this->assertSame(65, $this->page('admin', 1, ['page' => 1, 'category' => 'غير مصنّف'])['pagination']['total']);
        $this->assertSame(0, $this->page('admin', 1, ['page' => 1, 'category' => 'الرياضيات'])['pagination']['total']);
    }
}
