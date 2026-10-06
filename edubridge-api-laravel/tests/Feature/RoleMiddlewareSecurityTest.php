<?php

namespace Tests\Feature;

use App\Http\Middleware\RoleMiddleware;
use Illuminate\Http\Request;
use Tests\TestCase;

class RoleMiddlewareSecurityTest extends TestCase
{
    public function test_role_matching_is_type_strict(): void
    {
        $request = Request::create('/api/test', 'GET');
        $request->attributes->set('jwt_user', (object) ['role' => 0]);

        $response = (new RoleMiddleware())->handle(
            $request,
            fn () => response()->json(['ok' => true]),
            '0'
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_exact_role_still_passes(): void
    {
        $request = Request::create('/api/test', 'GET');
        $request->attributes->set('jwt_user', (object) ['role' => 'teacher']);

        $response = (new RoleMiddleware())->handle(
            $request,
            fn () => response()->json(['ok' => true]),
            'teacher'
        );

        $this->assertSame(200, $response->getStatusCode());
    }
}
