<?php

namespace Tests\Feature;

use App\Http\Controllers\UserController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class UserControllerPrivacyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->nullable();
            $table->string('role');
            $table->string('phone')->nullable();
            $table->string('national_id')->nullable();
            $table->string('verification_status')->default('pending');
            $table->timestamp('verified_at')->nullable();
            $table->string('specialty')->nullable();
            $table->timestamps();
        });

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
        });
        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });

        DB::table('users')->insert([
            [
                'id' => 1,
                'name' => 'ولي أمر',
                'email' => 'parent@example.com',
                'role' => 'parent',
                'phone' => '0599000000',
                'national_id' => '123456789',
                'verification_status' => 'verified',
                'specialty' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 2,
                'name' => 'معلم',
                'email' => 'teacher@example.com',
                'role' => 'teacher',
                'phone' => '0599111111',
                'national_id' => '987654321',
                'verification_status' => 'verified',
                'specialty' => 'تعليم خاص',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        DB::table('children')->insert(['id' => 10, 'assigned_teacher_id' => 2]);
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 1]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_ministry_does_not_receive_global_user_directory(): void
    {
        $response = app(UserController::class)->index(
            $this->request(10, 'ministry')
        );

        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame([], json_decode($response->getContent(), true)['users']);
    }

    public function test_parent_directory_exposes_only_assigned_staff_directory_fields(): void
    {
        $response = app(UserController::class)->index(
            $this->request(1, 'parent')
        );

        $this->assertSame(200, $response->getStatusCode());
        $users = json_decode($response->getContent(), true)['users'];
        $this->assertCount(1, $users);
        $this->assertSame(2, $users[0]['id']);
        $this->assertSame('معلم', $users[0]['name']);
        $this->assertSame('teacher', $users[0]['role']);
        $this->assertSame('تعليم خاص', $users[0]['specialty']);
        $this->assertArrayNotHasKey('email', $users[0]);
        $this->assertArrayNotHasKey('phone', $users[0]);
        $this->assertArrayNotHasKey('national_id', $users[0]);
    }

    public function test_admin_user_listing_keeps_management_contact_and_identity_data(): void
    {
        $response = app(UserController::class)->index(
            $this->request(11, 'admin')
        );

        $this->assertSame(200, $response->getStatusCode());
        $users = collect(json_decode($response->getContent(), true)['users'])->keyBy('id');
        $parent = $users[1];

        $this->assertSame('123456789', $parent['national_id']);
        $this->assertSame('parent@example.com', $parent['email']);
        $this->assertSame('0599000000', $parent['phone']);
    }

    private function request(int $id, string $role): Request
    {
        $request = Request::create('/api/users', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
