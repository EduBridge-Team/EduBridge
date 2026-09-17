<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class ChildAccessMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'غير مصرح'], 401);
        }

        $childId = $request->route('childId') ?? $request->route('id');
        if (!$childId) {
            return response()->json(['error' => 'معرّف الطفل مطلوب'], 400);
        }

        $child = DB::table('children')->where('id', $childId)->first();
        if (!$child) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }

        $allowed = match ($user->role) {
            'admin', 'specialist' => true,
            'teacher' => (int) ($child->assigned_teacher_id ?? 0) === (int) $user->id,
            'parent' => DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists(),
            default => false,
        };

        if (!$allowed) {
            return response()->json(['error' => 'لا تملك صلاحية الوصول إلى ملف هذا الطفل'], 403);
        }

        return $next($request);
    }
}
