<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class PasswordRecoveryExpiryTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->freezeTime();
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->string('password_hash');
            $table->timestamp('email_verified_at')->nullable();
        });
        foreach (['password_reset_tokens', 'email_verification_tokens'] as $name) {
            Schema::create($name, function (Blueprint $table) {
                $table->string('email')->primary();
                $table->string('token');
                $table->timestamp('created_at');
            });
        }
        DB::table('users')->insert(['email' => 'parent@example.com', 'password_hash' => password_hash('old-password', PASSWORD_BCRYPT)]);
    }

    protected function tearDown(): void
    {
        foreach (['email_verification_tokens', 'password_reset_tokens', 'users'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    public function test_expired_reset_token_cannot_change_password(): void
    {
        $this->token('password_reset_tokens', now()->subMinutes(61));
        $response = app(AuthController::class)->resetPassword($this->resetRequest());
        $this->assertSame(422, $response->getStatusCode());
        $this->assertTrue(password_verify('old-password', DB::table('users')->first()->password_hash));
    }

    public function test_reset_expires_at_exactly_sixty_minutes(): void
    {
        $this->token('password_reset_tokens', now()->subMinutes(60));
        $this->assertSame(422, app(AuthController::class)->resetPassword($this->resetRequest())->getStatusCode());
    }

    public function test_recent_token_changes_password_and_cannot_be_reused(): void
    {
        $this->token('password_reset_tokens', now()->subMinutes(59));
        $controller = app(AuthController::class);
        $this->assertSame(200, $controller->resetPassword($this->resetRequest())->getStatusCode());
        $this->assertTrue(password_verify('new-password', DB::table('users')->first()->password_hash));
        $this->assertSame(422, $controller->resetPassword($this->resetRequest())->getStatusCode());
    }

    public function test_expired_verification_link_does_not_verify_account(): void
    {
        $this->token('email_verification_tokens', now()->subHours(25));
        $request = Request::create('/api/auth/verify-email', 'GET', ['email' => 'parent@example.com', 'token' => 'test-token']);
        $response = app(AuthController::class)->verifyEmail($request);
        $this->assertStringEndsWith('/login?verified=0', $response->getTargetUrl());
        $this->assertNull(DB::table('users')->first()->email_verified_at);
    }

    private function token(string $table, $createdAt): void
    {
        DB::table($table)->insert(['email' => 'parent@example.com', 'token' => hash('sha256', 'test-token'), 'created_at' => $createdAt]);
    }

    private function resetRequest(): Request
    {
        return Request::create('/api/auth/reset-password', 'POST', ['email' => 'parent@example.com', 'token' => 'test-token', 'password' => 'new-password']);
    }
}
