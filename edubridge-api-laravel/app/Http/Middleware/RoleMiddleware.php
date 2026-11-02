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

        $allowed = $user && in_array($user->role, $roles, true);
        if (!$allowed && $user && in_array('school', $roles, true)) {
            $permission = $request->is('api/school/academic*') ? 'academic' : 'enrollment';
            $allowed = \App\Support\SchoolScopedAccess::resolve($request, $permission) !== null;
        }
        // A school role is not automatically a director. Enforce the same
        // read-only restriction for direct role:school routes as for school scope.
        if ($allowed && ($user->role ?? null) === 'school' && !$request->isMethod('GET')) {
            $allowed = \App\Support\SchoolScopedAccess::resolve($request, 'context') !== null;
        }

        if (!$allowed) {
            return response()->json(['error' => 'لا تملك صلاحية لهذا الإجراء'], 403);
        }

        return $next($request);
    }
}
