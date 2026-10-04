<?php

namespace Tests\Feature;

use Tests\TestCase;

class ProductionSecurityConfigurationTest extends TestCase
{
    public function test_production_compose_enforces_secure_session_cookie_settings(): void
    {
        $compose = file_get_contents(base_path('../deploy/oracle-compose.yml'));

        $this->assertIsString($compose);
        $this->assertStringContainsString('SESSION_SECURE_COOKIE: "true"', $compose);
        $this->assertStringContainsString('SESSION_HTTP_ONLY: "true"', $compose);
        $this->assertStringContainsString('SESSION_SAME_SITE: lax', $compose);
        $this->assertStringContainsString('SESSION_ENCRYPT: "true"', $compose);
    }

    public function test_localhost_cors_is_conditionally_enabled_only_for_local_or_testing(): void
    {
        $cors = file_get_contents(config_path('cors.php'));

        $this->assertIsString($cors);
        $this->assertStringContainsString("['local', 'testing']", $cors);
        $this->assertStringContainsString("$allowLocalOrigins ? [", $cors);
        $this->assertStringContainsString("'#^http://localhost:[0-9]+$#'", $cors);
        $this->assertStringContainsString("'#^http://127[.]0[.]1:[0-9]+$#'", $cors);
    }
}
