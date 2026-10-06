<?php

namespace Tests\Feature;

use App\Http\Controllers\UserController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class UserDirectoryAccessTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('role');
            $table->string('verification_status')->nullable();
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

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'Parent A', 'role' => 'parent', 'verification_status' => 'verified', 'specialty' => null],
            ['id' => 2, 'name' => 'Parent B', 'role' => 'parent', 'verification_status' => 'verified', 'specialty' => null],
            ['id' => 10, 'name' => 'Assigned Teacher', 'role' => 'teacher', 'verification_status' => 'verified', 'specialty' => null],
            ['id' => 11, 'name' => 'Team Teacher', 'role' => 'teacher', 'verification_status' => 'verified', 'specialty' => null],
            ['id' => 12, 'name' => 'Unrelated Teacher', 'role' => 'teacher', 'verification_status' => 'verified', 'specialty' => null],
            ['id' => 20, 'name' => 'Assigned Specialist', 'role' => 'specialist', 'verification_status' => 'verified', 'specialty' => 'educational'],
            ['id' => 21, 'name' => 'Unrelated Specialist', 'role' => 'specialist', 'verification_status' => 'verified', 'specialty' => 'learning_support'],
            ['id' => 30, 'name' => 'Admin', 'role' => 'admin', 'verification_status' => 'verified', 'specialty' => null],
            ['id' => 31, 'name' => 'Ministry', 'role' => 'ministry', 'verification_status' => 'verified', 'specialty' => null],
            ['id' => 32, 'name' => 'Institution', 'role' => 'institution', 'verification_status' => 'verified', 'specialty' => null],
        ]);

        DB::table('children')->insert([
            ['id' => 100, 'name' => 'Parent A Child', 'assigned_teacher_id' => 10],
            ['id' => 200, 'name' => 'Other Child', 'assigned_teacher_id' => 12],
        ]);
        DB::table('child_parent')->insert([
            ['child_id' => 100, 'parent_id' => 1],
            ['child_id' => 200, 'parent_id' => 2],
        ]);
        DB::table('child_teacher')->insert([
            ['child_id' => 100, 'teacher_id' => 11],
        ]);
        DB::table('child_specialist')->insert([
            ['child_id' => 100, 'specialist_id' => 20],
            ['child_id' => 200, 'specialist_id' => 21],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_parent_only_sees_staff_assigned_to_their_children(): void
    {
        $users = $this->directory(1, 'parent');

        $this->assertEqualsCanonicalizing([10, 11, 20], array_column($users, 'id'));
        $this->assertNotContains(12, array_column($users, 'id'));
        $this->assertNotContains(21, array_column($users, 'id'));
    }

    public function test_ministry_and_institution_do_not_receive_global_user_directory(): void
    {
        $this->assertSame([], $this->directory(31, 'ministry'));
        $this->assertSame([], $this->directory(32, 'institution'));
    }

    public function test_staff_picker_only_exposes_teacher_and_specialist_roles(): void
    {
        $users = $this->directory(20, 'specialist');
        $roles = array_values(array_unique(array_column($users, 'role')));

        $this->assertEqualsCanonicalizing(['teacher', 'specialist'], $roles);
        $this->assertNotContains(20, array_column($users, 'id'));
        $this->assertNotContains(30, array_column($users, 'id'));
        $this->assertNotContains(31, array_column($users, 'id'));
        $this->assertNotContains(32, array_column($users, 'id'));
    }

    private function directory(int $id, string $role): array
    {
        $request = Request::create('/api/users', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        $response = app(UserController::class)->index($request);
        $this->assertSame(200, $response->getStatusCode());

        return $response->getData(true)['users'];
    }
}
