<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LearningSupportRequestReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['parent', 'specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $query = $this->requestQuery()->orderByDesc('tr.created_at');

            if ($user->role === 'parent') {
                $query->where('tr.parent_id', $user->id);
            }

            if ($request->filled('child_id')) {
                $childId = (int) $request->query('child_id');
                if (!$this->canViewChild($user, $childId)) {
                    return response()->json(['error' => 'غير مصرّح'], 403);
                }
                $query->where('tr.child_id', $childId);
            }

            if ($request->filled('status')) {
                $status = (string) $request->query('status');
                if (!in_array($status, ['pending', 'scheduled', 'completed', 'cancelled'], true)) {
                    return response()->json(['error' => 'الحالة غير صالحة'], 422);
                }
                $query->where('tr.status', $status);
            }

            return response()->json(['requests' => $query->get()]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'تعذّر تحميل الطلبات'], 500);
        }
    }

    public function pendingForChild(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = (int) $childId;

        if (!$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $query = DB::table('learning_support_requests')
            ->where('child_id', $childId)
            ->whereIn('status', ['pending', 'scheduled']);

        if ($user->role === 'parent') {
            $query->where('parent_id', $user->id);
        }

        return response()->json(['has_pending' => $query->exists()]);
    }
}
