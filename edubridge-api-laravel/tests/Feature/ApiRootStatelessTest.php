<?php

namespace Tests\Feature;

use Tests\TestCase;

class ApiRootStatelessTest extends TestCase
{
    public function test_api_root_is_stateless_and_does_not_set_session_or_xsrf_cookies(): void
    {
        $response = $this->get('/');

        $response->assertOk()
            ->assertJson([
                'message' => 'EduBridge API شغّال ✅',
            ]);

        $this->assertFalse($response->headers->has('Set-Cookie'));
    }

    public function test_unknown_non_api_paths_do_not_masquerade_as_health_endpoints(): void
    {
        $this->get('/actuator/health')->assertNotFound();
        $this->get('/actuator')->assertNotFound();
    }
}
