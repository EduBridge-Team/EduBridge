<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AuthRegistrationPrivacyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password_hash');
            $table->string('role');
            $table->string('phone')->nullable();
            $table->string('specialty')->nullable();
            $table->string('verification_status')->default('pending');
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_registration_response_never_exposes_password_hash(): void
    {
        $request = Request::create('/api/auth/register', 'POST', [
            'name' => 'ولي أمر',
            'email' => 'parent@example.com',
            'password' => 'very-secret-password',
            'role' => 'parent',
            'phone' => '0599000000',
        ]);
        $request->headers->set('Accept', 'application/json');

        $response = app(AuthController::class)->register($request);

        $this->assertSame(201, $response->getStatusCode());

        $payload = json_decode($response->getContent(), true);
        $this->assertArrayHasKey('user', $payload);
        $this->assertArrayNotHasKey('password_hash', $payload['user']);
        $this->assertArrayNotHasKey('password', $payload['user']);
        $this->assertSame('parent@example.com', $payload['user']['email']);
        $this->assertSame('parent', $payload['user']['role']);
    }
    public function test_public_registration_rejects_privileged_roles(): void
    {
        foreach (['admin', 'ministry', 'institution'] as $role) {
            $request = Request::create('/api/auth/register', 'POST', [
                'name' => 'حساب إداري',
                'email' => $role . '@example.com',
                'password' => 'safe-password-123',
                'role' => $role,
            ]);
            $request->headers->set('Accept', 'application/json');

            $response = app(AuthController::class)->register($request);

            $this->assertSame(400, $response->getStatusCode(), "Role {$role} must not self-register");
        }
    }

    public function test_registration_rejects_invalid_email(): void
    {
        $request = Request::create('/api/auth/register', 'POST', [
            'name' => 'مستخدم',
            'email' => 'not-an-email',
            'password' => 'safe-password-123',
            'role' => 'parent',
        ]);

        $response = app(AuthController::class)->register($request);

        $this->assertSame(422, $response->getStatusCode());
    }

    public function test_registration_rejects_short_password(): void
    {
        $request = Request::create('/api/auth/register', 'POST', [
            'name' => 'مستخدم',
            'email' => 'short@example.com',
            'password' => '1234567',
            'role' => 'parent',
        ]);

        $response = app(AuthController::class)->register($request);

        $this->assertSame(422, $response->getStatusCode());
    }

    public function test_specialist_can_register_with_supported_specialty(): void
    {
        $request = Request::create('/api/auth/register', 'POST', [
            'name' => 'مختص تعليمي',
            'email' => 'specialist@example.com',
            'password' => 'safe-password-123',
            'role' => 'specialist',
            'specialty' => 'learning_support',
        ]);
        $request->headers->set('Accept', 'application/json');

        $response = app(AuthController::class)->register($request);

        $this->assertSame(201, $response->getStatusCode());
        $payload = json_decode($response->getContent(), true);
        $this->assertSame('learning_support', $payload['user']['specialty']);
    }

}
