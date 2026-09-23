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

        DB::table('users')->insert([
            [
                'id' => 1,
                'name' => 'ولي أمر',
                'email' => 'parent@example.com',
                'role' => 'parent',
                'phone' => '0599000000',
                'national_id' => '123456789',
                'verification_status' => 'verified',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_ministry_user_listing_omits_national_id(): void
    {
        $response = app(UserController::class)->index(
            $this->request(10, 'ministry')
        );

        $this->assertSame(200, $response->getStatusCode());
        $user = json_decode($response->getContent(), true)['users'][0];

        $this->assertArrayNotHasKey('national_id', $user);
    }

    public function test_admin_user_listing_can_include_national_id(): void
    {
        $response = app(UserController::class)->index(
            $this->request(11, 'admin')
        );

        $this->assertSame(200, $response->getStatusCode());
        $user = json_decode($response->getContent(), true)['users'][0];

        $this->assertSame('123456789', $user['national_id']);
    }

    private function request(int $id, string $role): Request
    {
        $request = Request::create('/api/users', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
