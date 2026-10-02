<?php

namespace Tests\Feature;

use App\Http\Controllers\NotificationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class NotificationPaginationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('notifications', function (Blueprint $table) {
            $table->id(); $table->integer('user_id'); $table->string('title');
            $table->string('message'); $table->string('type');
            $table->boolean('is_read')->default(false); $table->timestamp('created_at');
        });
        foreach (range(1, 105) as $id) {
            DB::table('notifications')->insert([
                'id' => $id, 'user_id' => $id % 5 === 0 ? 2 : 1,
                'title' => "Notification $id", 'message' => 'Body', 'type' => 'test',
                'is_read' => $id % 2 === 0, 'created_at' => '2026-10-02 12:00:00',
            ]);
        }
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('notifications');
        parent::tearDown();
    }

    private function page(array $params = []): array
    {
        $request = Request::create('/api/notifications', 'GET', $params);
        $request->attributes->set('jwt_user', (object) ['id' => 1]);
        $response = app(NotificationController::class)->index($request);
        $this->assertSame(200, $response->getStatusCode());
        return $response->getData(true);
    }

    public function test_history_pages_cover_tied_timestamps_without_duplicates_or_cross_account_data(): void
    {
        $expected = array_values(array_filter(range(105, 1), fn ($id) => $id % 5 !== 0));
        $all = []; $params = ['limit' => 7];
        do {
            $page = $this->page($params);
            $this->assertLessThanOrEqual(7, count($page['notifications']));
            $this->assertSame(42, $page['unread_count']);
            foreach ($page['notifications'] as $item) {
                $this->assertSame(1, $item['user_id']);
                $this->assertSame('Body', $item['body']);
                $all[] = $item['id'];
            }
            $params['before_id'] = $page['pagination']['next_before_id'];
        } while ($page['pagination']['has_more']);
        $this->assertSame($expected, $all);
        $this->assertNull($page['pagination']['next_before_id']);
    }

    public function test_delta_pages_drain_oldest_first_and_preserve_cursor_when_empty(): void
    {
        $all = []; $after = 0;
        do {
            $page = $this->page(['limit' => 9, 'after_id' => $after]);
            $all = array_merge($all, array_column($page['notifications'], 'id'));
            $after = $page['pagination']['next_after_id'];
        } while ($page['pagination']['has_more']);
        $this->assertSame(array_values(array_filter(range(1, 105), fn ($id) => $id % 5 !== 0)), $all);
        $empty = $this->page(['after_id' => $after]);
        $this->assertSame([], $empty['notifications']);
        $this->assertSame($after, $empty['pagination']['next_after_id']);
        $this->assertFalse($empty['pagination']['has_more']);
    }

    public function test_new_arrivals_do_not_shift_older_history_pages(): void
    {
        $first = $this->page(['limit' => 10]);
        DB::table('notifications')->insert(['id' => 106, 'user_id' => 1, 'title' => 'New', 'message' => 'New', 'type' => 'test', 'is_read' => false, 'created_at' => now()]);
        $older = $this->page(['limit' => 10, 'before_id' => $first['pagination']['next_before_id']]);
        $this->assertSame([], array_intersect(array_column($first['notifications'], 'id'), array_column($older['notifications'], 'id')));
        $this->assertSame([106], array_column($this->page(['after_id' => 104])['notifications'], 'id'));
    }

    public function test_legacy_list_is_complete_and_unread_filter_retains_global_badge(): void
    {
        $legacy = $this->page();
        $this->assertCount(84, $legacy['notifications']);
        $this->assertArrayNotHasKey('pagination', $legacy);
        $unread = $this->page(['limit' => 100, 'unread' => '1']);
        $this->assertCount(42, $unread['notifications']);
        $this->assertSame(42, $unread['unread_count']);
        foreach ($unread['notifications'] as $row) $this->assertFalse((bool) $row['is_read']);
    }

    public function test_invalid_paging_parameters_are_validation_errors_not_server_errors(): void
    {
        foreach ([['limit' => 0], ['limit' => 101], ['limit' => 'bad'], ['before_id' => 0], ['after_id' => -1], ['before_id' => 4, 'after_id' => 1], ['limit' => '']] as $params) {
            try {
                $this->page($params);
                $this->fail('Invalid pagination accepted');
            } catch (ValidationException $exception) {
                $this->assertSame(422, $exception->status);
            }
        }
    }
}
