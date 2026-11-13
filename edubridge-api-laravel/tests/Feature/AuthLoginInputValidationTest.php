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

    public function test_login_keeps_the_existing_missing_credentials_response(): void
    {
        foreach ([[], ['email' => 'qa-input@example.test'], ['password' => 'test-only-value']] as $payload) {
            $response = (new AuthController())->login(Request::create('/api/auth/login', 'POST', $payload));
            $this->assertSame(400, $response->getStatusCode());
        }
    }
}
