<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use Illuminate\Http\Request;
use Tests\TestCase;

class AuthLoginInputValidationTest extends TestCase
{
    public function test_login_rejects_non_string_credentials_before_database_access(): void
    {
        $invalidValues = [['invalid'], ['value' => 'invalid'], 123, true, null];

        foreach (['email', 'password'] as $field) {
            foreach ($invalidValues as $value) {
                $payload = ['email' => 'qa-input@example.test', 'password' => 'test-only-value'];
                $payload[$field] = $value;
                $response = (new AuthController())->login(Request::create('/api/auth/login', 'POST', $payload));

                $this->assertSame(400, $response->getStatusCode(), $field . ' must be a string');
                $this->assertSame('الإيميل والباسورد مطلوبان', $response->getData(true)['error']);
            }
        }
    }

    public function test_http_login_rejects_non_string_json_fields_before_the_rate_limiter(): void
    {
        foreach ([
            ['email' => ['invalid'], 'password' => 'test-only-value'],
            ['email' => ['value' => 'invalid'], 'password' => 'test-only-value'],
            ['email' => 'qa-input@example.test', 'password' => ['invalid']],
        ] as $payload) {
            $this->postJson('/api/auth/login', $payload)
                ->assertStatus(400)
                ->assertJson(['error' => 'الإيميل والباسورد مطلوبان']);
        }
    }

    public function test_account_recovery_rate_limiter_handles_non_string_email(): void
    {
        $limiter = \Illuminate\Support\Facades\RateLimiter::limiter('auth-recovery');
        $this->assertNotNull($limiter);
        $request = Request::create('/api/auth/forgot-password', 'POST', ['email' => ['invalid']]);
        $this->assertCount(2, $limiter($request));
    }

    public function test_login_keeps_the_existing_missing_credentials_response(): void
    {
        foreach ([[], ['email' => 'qa-input@example.test'], ['password' => 'test-only-value']] as $payload) {
            $response = (new AuthController())->login(Request::create('/api/auth/login', 'POST', $payload));
            $this->assertSame(400, $response->getStatusCode());
        }
    }
}
