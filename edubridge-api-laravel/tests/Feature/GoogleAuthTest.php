<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GoogleAuthTest extends TestCase
{
    public function test_google_login_requires_an_id_token(): void
    {
        $response = $this->postJson('/api/auth/google', []);

        $response->assertStatus(400);
        $response->assertJsonPath('error', 'الرمز المرسل من Google مطلوب');
    }

    public function test_google_login_rejects_unverified_email(): void
    {
        putenv('GOOGLE_CLIENT_ID=test-client');
        $_ENV['GOOGLE_CLIENT_ID'] = 'test-client';

        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => 'test-client',
                'email' => 'person@example.com',
                'name' => 'Person',
                'email_verified' => 'false',
            ], 200),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'id_token' => 'fake-token',
        ]);

        $response->assertStatus(401);
        $response->assertJsonPath('error', 'البريد الإلكتروني في حساب Google غير موثّق');

        putenv('GOOGLE_CLIENT_ID');
        unset($_ENV['GOOGLE_CLIENT_ID']);
    }
}
