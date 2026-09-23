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

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');

        parent::tearDown();
    }

    public function test_parent_can_create_child_and_is_linked_automatically(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(1, 'parent', ['name' => 'طفل ولي الأمر'])
        );

        $this->assertSame(201, $response->getStatusCode());

        $childId = DB::table('children')->where('name', 'طفل ولي الأمر')->value('id');
        $this->assertNotNull($childId);
        $this->assertDatabaseHas('child_parent', [
            'child_id' => $childId,
            'parent_id' => 1,
        ]);
    }

    public function test_admin_can_create_child_without_parent_link(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(5, 'admin', ['name' => 'طفل الأدمن'])
        );

        $this->assertSame(201, $response->getStatusCode());

        $childId = DB::table('children')->where('name', 'طفل الأدمن')->value('id');
        $this->assertNotNull($childId);
        $this->assertDatabaseMissing('child_parent', ['child_id' => $childId]);
    }

    public function test_teacher_cannot_create_child(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(2, 'teacher', ['name' => 'طفل المعلم'])
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('children', ['name' => 'طفل المعلم']);
    }

    public function test_specialist_cannot_create_child(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(3, 'specialist', ['name' => 'طفل المختص'])
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('children', ['name' => 'طفل المختص']);
    }

    private function request(int $id, string $role, array $payload): Request
    {
        $request = Request::create('/api/children', 'POST', $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
