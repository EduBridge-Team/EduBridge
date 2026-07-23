<?php

namespace App\Http\Middleware;

// ميدل وير الصلاحيات: يسمح فقط لأدوار معيّنة
use Closure;
use Illuminate\Http\Request;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || !in_array($user->role, $roles)) {
            return response()->json(['error' => 'لا تملك صلاحية لهذا الإجراء'], 403);
        }

        return $next($request);
    }
}
