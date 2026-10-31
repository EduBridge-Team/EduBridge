<?php

namespace App\Http\Middleware;

// ميدل وير الصلاحيات: يسمح فقط لأدوار معيّنة
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        $user = $request->attributes->get('jwt_user');

        $allowed = $user && in_array($user->role, $roles, true);
        if (!$allowed && $user && in_array('school', $roles, true)) {
            $allowed = DB::table('school_management_assignments as a')
                ->join('schools as s', 's.id', '=', 'a.school_id')
                ->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
                ->where('a.user_id', $user->id)
                ->where('a.role', 'director')
                ->whereNull('a.ends_at')
                ->where('s.is_active', true)
                ->where(function ($q) {
                    $q->whereNull('s.organization_id')->orWhere('o.is_active', true);
                })->exists();
        }
        if (!$allowed) {
            return response()->json(['error' => 'لا تملك صلاحية لهذا الإجراء'], 403);
        }

        return $next($request);
    }
}
