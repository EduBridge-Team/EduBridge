<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrganizationMembershipMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'المستخدم غير مصادق عليه'], 401);
        }

        $slug = (string) $request->route('organizationSlug');
        $organization = DB::table('organizations')
            ->where('slug', $slug)
            ->where('is_active', true)
            ->first();

        if (!$organization) {
            return response()->json(['error' => 'المؤسسة غير موجودة'], 404);
        }

        // Platform administrators may inspect/manage any tenant, but every request
        // is still bound to one explicit organization to avoid accidental leakage.
        if (($user->role ?? null) === 'admin') {
            $request->attributes->set('organization', $organization);
            $request->attributes->set('organization_role', 'platform_admin');
            return $next($request);
        }

        $membership = DB::table('organization_user')
            ->where('organization_id', $organization->id)
            ->where('user_id', $user->id)
            ->where('is_active', true)
            ->first();

        if (!$membership) {
            return response()->json(['error' => 'لا تملك عضوية فعالة في هذه المؤسسة'], 403);
        }

        if ($roles !== [] && !in_array($membership->role, $roles, true)) {
            return response()->json(['error' => 'لا تملك صلاحية لهذا الإجراء داخل المؤسسة'], 403);
        }

        $request->attributes->set('organization', $organization);
        $request->attributes->set('organization_role', $membership->role);

        return $next($request);
    }
}
