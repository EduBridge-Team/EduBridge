<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolLoginScopeTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('email')->unique();
            $table->string('password_hash');
            $table->string('role');
        });
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id')->nullable();
            $table->boolean('is_active');
        });
        Schema::create('school_accounts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('school_id');
        });
        DB::table('users')->insert([
            'id' => 7, 'email' => 'school@example.org',
            'password_hash' => password_hash('valid-password-123', PASSWORD_BCRYPT),
            'role' => 'school',
        ]);
        DB::table('organizations')->insert(['id' => 4, 'is_active' => true]);
        DB::table('schools')->insert(['id' => 10, 'organization_id' => 4, 'is_active' => true]);
    }

    protected function tearDown(): void
    {
        foreach (['school_accounts', 'schools', 'organizations', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function attempt(): \Illuminate\Http\Response|\Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/auth/login', 'POST', [
            'email' => 'school@example.org',
            'password' => 'valid-password-123',
        ]);
        return app(AuthController::class)->login($request);
    }

    public function test_unlinked_school_login_is_denied(): void
    {
        $response = $this->attempt();
        $this->assertSame(403, $response->getStatusCode());
        $this->assertSame('SCHOOL_ACCESS_UNAVAILABLE', $response->getData(true)['code']);
    }

    public function test_inactive_school_and_institution_cannot_log_in(): void
    {
        DB::table('school_accounts')->insert(['id' => 1, 'school_id' => 10, 'user_id' => 7]);
        DB::table('schools')->where('id', 10)->update(['is_active' => false]);
        $this->assertSame(403, $this->attempt()->getStatusCode());

        DB::table('schools')->where('id', 10)->update(['is_active' => true]);
        DB::table('organizations')->where('id', 4)->update(['is_active' => false]);
        $this->assertSame(403, $this->attempt()->getStatusCode());
    }
    public function test_two_active_school_bindings_block_login(): void
    {
        DB::table('schools')->insert([
            'id' => 11, 'organization_id' => null, 'is_active' => true,
        ]);
        DB::table('school_accounts')->insert([
            ['school_id' => 10, 'user_id' => 7],
            ['school_id' => 11, 'user_id' => 7],
        ]);
        $response = $this->attempt();
        $this->assertSame(403, $response->getStatusCode());
        $this->assertSame('SCHOOL_ACCESS_UNAVAILABLE', $response->getData(true)['code']);
    }

    public function test_duplicate_binding_to_one_school_blocks_login(): void
    {
        DB::table('school_accounts')->insert([
            ['school_id' => 10, 'user_id' => 7],
            ['school_id' => 10, 'user_id' => 7],
        ]);
        $response = $this->attempt();
        $this->assertSame(403, $response->getStatusCode());
        $this->assertSame('SCHOOL_ACCESS_UNAVAILABLE', $response->getData(true)['code']);
    }

    public function test_foreign_user_school_binding_does_not_authorize_login(): void
    {
        DB::table('school_accounts')->insert(['school_id' => 10, 'user_id' => 999]);
        $response = $this->attempt();
        $this->assertSame(403, $response->getStatusCode());
        $this->assertSame('SCHOOL_ACCESS_UNAVAILABLE', $response->getData(true)['code']);
    }

}
