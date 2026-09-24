<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;

trait SessionReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = $this->baseQuery();

            if ($user->role === 'specialist') {
                $query->where('s.specialist_id', $user->id);
            } elseif ($user->role === 'teacher') {
                $query->where(function ($q) use ($user) {
                    $q->whereIn('s.child_id', function ($sub) use ($user) {
                        $sub->from('children')
                            ->select('id')
                            ->where('assigned_teacher_id', $user->id);
                    })->orWhereIn('s.child_id', function ($sub) use ($user) {
                        $sub->from('child_teacher')
                            ->select('child_id')
                            ->where('teacher_id', $user->id);
                    });
                });
            } elseif ($user->role === 'parent') {
                $query->join('child_parent as cp', 'cp.child_id', '=', 's.child_id')
                    ->where('cp.parent_id', $user->id);
            }

            if ($request->filled('child_id')) {
                $childId = (int) $request->query('child_id');
                if (!$this->canAccessChild($user, $childId)) {
                    return response()->json(['error' => 'غير مصرّح'], 403);
                }
                $query->where('s.child_id', $childId);
            }

            $sessions = $query->get()->map(fn ($session) => $this->normalizeSession($session));
            return response()->json(['sessions' => $sessions]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل اجتماعات الدعم'], 500);
        }
    }

    public function byChild(Request $request, $childId)
    {
        $request->query->set('child_id', $childId);

        return $this->index($request);
    }
}
