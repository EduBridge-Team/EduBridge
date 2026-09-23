<?php

namespace Tests\Feature;

use App\Http\Controllers\ChildAccessibilityProfileController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildAccessibilityProfileControllerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
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

        Schema::create('child_accessibility_profiles', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('child_id')->unique();
            $table->text('profile');
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();
        });

        DB::table('children')->insert([
            ['id' => 10, 'assigned_teacher_id' => 2],
            ['id' => 20, 'assigned_teacher_id' => null],
        ]);
        DB::table('child_teacher')->insert(['child_id' => 20, 'teacher_id' => 3]);
        DB::table('child_specialist')->insert(['child_id' => 10, 'specialist_id' => 4]);
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 5]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_accessibility_profiles');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');

        parent::tearDown();
    }

    public function test_assigned_staff_and_parent_can_access_the_child_profile(): void
    {
        $controller = app(ChildAccessibilityProfileController::class);

        foreach ([
            [2, 'teacher', 10],
            [3, 'teacher', 20],
            [4, 'specialist', 10],
            [5, 'parent', 10],
        ] as [$userId, $role, $childId]) {
            $response = $controller->show($this->request('GET', [], $userId, $role), $childId);
            $this->assertSame(200, $response->getStatusCode());
        }
    }

    public function test_unassigned_staff_cannot_access_another_child_profile(): void
    {
        $controller = app(ChildAccessibilityProfileController::class);

        $teacher = $controller->show($this->request('GET', [], 99, 'teacher'), 10);
        $specialist = $controller->show($this->request('GET', [], 98, 'specialist'), 10);

        $this->assertSame(403, $teacher->getStatusCode());
        $this->assertSame(403, $specialist->getStatusCode());
    }

    public function test_authorized_user_can_update_profile_but_outsider_cannot(): void
    {
        $controller = app(ChildAccessibilityProfileController::class);
        $payload = ['profile' => ['largeText' => true, 'highContrast' => false]];

        $allowed = $controller->update($this->request('PUT', $payload, 5, 'parent'), 10);
        $this->assertSame(200, $allowed->getStatusCode());
        $this->assertDatabaseHas('child_accessibility_profiles', [
            'child_id' => 10,
            'updated_by' => 5,
        ]);

        $blocked = $controller->update($this->request('PUT', $payload, 77, 'parent'), 10);
        $this->assertSame(403, $blocked->getStatusCode());
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/children/10/accessibility-profile', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
