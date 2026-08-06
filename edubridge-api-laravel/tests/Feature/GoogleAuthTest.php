<?php

namespace Tests\Feature;

use Tests\TestCase;

class GoogleAuthTest extends TestCase
{
    public function test_google_login_requires_an_id_token(): void
    {
        $response = $this->postJson('/api/auth/google', []);

        $response->assertStatus(400);
        $response->assertJsonPath('error', 'الرمز المرسل من Google مطلوب');
    }
}
