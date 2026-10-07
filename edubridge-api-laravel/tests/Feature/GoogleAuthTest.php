<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
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

    public function test_new_google_account_requires_a_public_role(): void
    {
        $this->createMinimalUsersTable();
        putenv('GOOGLE_CLIENT_ID=test-client');
        $_ENV['GOOGLE_CLIENT_ID'] = 'test-client';

        try {
            Http::fake([
                'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                    'aud' => 'test-client',
                    'email' => 'new-google-user@example.com',
                    'name' => 'New Google User',
                    'email_verified' => 'true',
                ], 200),
            ]);

            $response = $this->postJson('/api/auth/google', [
                'id_token' => 'fake-token',
            ]);

            $response->assertStatus(422);
            $response->assertJsonPath('code', 'GOOGLE_ROLE_REQUIRED');
            $response->assertJsonPath('allowed_roles.0', 'parent');
            $response->assertJsonPath('allowed_roles.1', 'teacher');
            $response->assertJsonPath('allowed_roles.2', 'specialist');
        } finally {
            Schema::dropIfExists('users');
            putenv('GOOGLE_CLIENT_ID');
            unset($_ENV['GOOGLE_CLIENT_ID']);
        }
    }

    public function test_new_google_account_cannot_self_assign_privileged_role(): void
    {
        $this->createMinimalUsersTable();
        putenv('GOOGLE_CLIENT_ID=test-client');
        $_ENV['GOOGLE_CLIENT_ID'] = 'test-client';

        try {
            Http::fake([
                'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                    'aud' => 'test-client',
                    'email' => 'google-admin-attempt@example.com',
                    'name' => 'Google User',
                    'email_verified' => true,
                ], 200),
            ]);

            $response = $this->postJson('/api/auth/google', [
                'id_token' => 'fake-token',
                'role' => 'admin',
            ]);

            $response->assertStatus(422);
            $response->assertJsonPath('code', 'GOOGLE_ROLE_REQUIRED');
        } finally {
            Schema::dropIfExists('users');
            putenv('GOOGLE_CLIENT_ID');
            unset($_ENV['GOOGLE_CLIENT_ID']);
        }
    }

    private function createMinimalUsersTable(): void
    {
        Schema::dropIfExists('users');
        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('email')->unique();
        });
    }
}
