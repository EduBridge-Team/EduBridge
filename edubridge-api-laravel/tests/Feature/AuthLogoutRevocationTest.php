<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AuthLogoutRevocationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('session_version')->default(0);
        });

        DB::table('users')->insert(['id' => 7, 'session_version' => 3]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_logout_increments_session_version(): void
    {
        $request = Request::create('/api/auth/logout', 'POST');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);

        $response = app(AuthController::class)->logout($request);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame(4, DB::table('users')->where('id', 7)->value('session_version'));
    }
}
