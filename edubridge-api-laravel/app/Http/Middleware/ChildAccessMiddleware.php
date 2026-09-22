<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class ChildAccessMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return $next($request);
        }

        // قائمة الأطفال: الوزارة والمؤسسة تستخدمان مساراتهما المخصصة،
        // والمعلّم لا يرى إلا الأطفال المسندين إليه.
        if ($request->is('api/children') && $request->isMethod('get')) {
            if (in_array($user->role, ['ministry', 'institution'], true)) {
                return response()->json(['error' => 'هذه الصفحة غير متاحة لهذا الدور'], 403);
            }

            $response = $next($request);
            if ($user->role !== 'teacher' || !($response instanceof JsonResponse)) {
                return $response;
            }

            $payload = $response->getData(true);
            $payload['children'] = array_values(array_filter(
                $payload['children'] ?? [],
                fn ($child) => (int) ($child['assigned_teacher_id'] ?? 0) === (int) $user->id
            ));
            $response->setData($payload);
            return $response;
        }

        $childScoped =
            $request->is('api/children/*') ||
            $request->is('api/progress/child/*') ||
            $request->is('api/evaluations/child/*') ||
            $request->is('api/sessions/child/*') ||
            $request->is('api/learning-support/requests/child/*');

        if (!$childScoped) {
            return $next($request);
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
