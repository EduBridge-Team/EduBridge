<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RequireIdentityVerification
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->attributes->get('jwt_user');
        // These routes must remain usable while the account awaits approval.
        $onboarding = $request->is(
            'api/me', 'api/me/*', 'api/settings', 'api/uploads', 'api/certificates',
            'api/certificates/*', 'api/private-files/user/*', 'api/support', 'api/support/*'
        );
        if ($user && (in_array($user->role, ['admin', 'parent'], true) || $onboarding
            || ($user->verification_status ?? null) === 'verified')) {
            return $next($request);
        }

        return response()->json([
            'error' => 'توثيق الهوية مطلوب لاستخدام هذه الخدمة',
            'code' => 'IDENTITY_NOT_VERIFIED',
        ], 403);
    }
}
