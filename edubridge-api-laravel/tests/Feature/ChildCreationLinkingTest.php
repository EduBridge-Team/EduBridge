<?php

namespace Tests\Feature;

use App\Http\Controllers\ChildController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildCreationLinkingTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('role');
            $table->string('specialty')->nullable();
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
            $table->string('specialty')->nullable();
            $table->timestamp('assigned_at')->nullable();
            $table->timestamp('created_at')->nullable();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'ولي أمر', 'role' => 'parent', 'specialty' => null],
            ['id' => 2, 'name' => 'معلم', 'role' => 'teacher', 'specialty' => null],
            ['id' => 3, 'name' => 'مختص', 'role' => 'specialist', 'specialty' => 'learning_support'],
            ['id' => 4, 'name' => 'مختص بلا تخصص', 'role' => 'specialist', 'specialty' => null],
            ['id' => 5, 'name' => 'أدمن', 'role' => 'admin', 'specialty' => null],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_teacher_created_child_is_assigned_to_teacher(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(2, 'teacher', ['name' => 'طفل المعلم'])
        );

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('children', [
            'name' => 'طفل المعلم',
            'assigned_teacher_id' => 2,
        ]);
    }

    public function test_specialist_created_child_is_added_to_specialist_team(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(3, 'specialist', ['name' => 'طفل المختص'])
        );

        $this->assertSame(201, $response->getStatusCode());

        $childId = DB::table('children')->where('name', 'طفل المختص')->value('id');
        $this->assertNotNull($childId);
        $this->assertDatabaseHas('child_specialist', [
            'child_id' => $childId,
            'specialist_id' => 3,
            'specialty' => 'learning_support',
        ]);
    }

    public function test_specialist_without_specialty_cannot_create_orphan_child(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(4, 'specialist', ['name' => 'طفل بلا ربط'])
        );

        $this->assertSame(422, $response->getStatusCode());
        $this->assertDatabaseMissing('children', ['name' => 'طفل بلا ربط']);
    }

    public function test_parent_created_child_is_linked_to_parent(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(1, 'parent', ['name' => 'طفل ولي الأمر'])
        );

        $this->assertSame(201, $response->getStatusCode());

        $childId = DB::table('children')->where('name', 'طفل ولي الأمر')->value('id');
        $this->assertDatabaseHas('child_parent', [
            'child_id' => $childId,
            'parent_id' => 1,
        ]);
    }

    private function request(int $id, string $role, array $payload): Request
    {
        $request = Request::create('/api/children', 'POST', $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
