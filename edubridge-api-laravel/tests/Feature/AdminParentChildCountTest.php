<?php

namespace Tests\Feature;

use App\Http\Controllers\UserController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AdminParentChildCountTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            foreach (['name', 'email', 'role', 'phone', 'verification_status', 'national_id'] as $field) {
                $table->string($field)->nullable();
            }
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('created_at')->nullable();
        });
        Schema::create('children', fn (Blueprint $table) => $table->id());
        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });
        DB::table('users')->insert([
            ['id' => 1, 'name' => 'ولي أمر', 'role' => 'parent'],
            ['id' => 2, 'name' => 'ولي أمر آخر', 'role' => 'parent'],
        ]);
        DB::table('children')->insert([['id' => 10], ['id' => 20]]);
        DB::table('child_parent')->insert([
            ['child_id' => 10, 'parent_id' => 1],
            ['child_id' => 10, 'parent_id' => 1],
            ['child_id' => 20, 'parent_id' => 1],
            ['child_id' => 10, 'parent_id' => 2],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_admin_counts_distinct_children_for_each_parent_relation(): void
    {
        $request = Request::create('/api/users', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => 9, 'role' => 'admin']);
        $response = app(UserController::class)->index($request);
        $this->assertSame(200, $response->getStatusCode());
        $users = collect($response->getData(true)['users'])->keyBy('id');
        $this->assertSame(2, (int) $users[1]['parent_children_count']);
        $this->assertSame(1, (int) $users[2]['parent_children_count']);
    }

    public function test_parent_does_not_receive_admin_relation_counts(): void
    {
        $request = Request::create('/api/users', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'parent']);
        $response = app(UserController::class)->index($request);
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame([], $response->getData(true)['users']);
    }
}
