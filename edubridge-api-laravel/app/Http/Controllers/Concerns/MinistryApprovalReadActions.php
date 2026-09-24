<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait MinistryApprovalReadActions
{
    public function index(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $query = $this->query();

        if (!in_array($me->role, ['ministry','admin'], true)) {
            if ($me->role === 'teacher') {
                $query->where(function ($q) use ($me) {
                    $q->where('a.submitted_by', $me->id)
                        ->orWhere('a.teacher_id', $me->id);
                });
            } else {
                $query->where('a.submitted_by', $me->id);
            }
        }

        $status = trim((string) $request->query('status', ''));
        if ($status !== '') {
            $statuses = array_values(array_filter(array_map('trim', explode(',', $status))));
            $valid = array_values(array_intersect($statuses, ['pending','approved','rejected']));
            if ($valid) {
                $query->whereIn('a.status', $valid);
            }
        }

        return response()->json([
            'approvals' => $query->get()->map(fn ($row) => $this->normalize($row))->values(),
        ]);
    }

    public function pending(Request $request)
    {
        $request->query->set('status', 'pending');

        return $this->index($request);
    }

    public function childStatus(Request $request, $childId)
    {
        $me = $request->attributes->get('jwt_user');
        if (!$this->canAccessChild($me, (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $row = DB::table('ministry_approvals')
            ->where('child_id', $childId)
            ->orderByDesc('created_at')
            ->first();

        return response()->json(['status' => $row->status ?? 'none']);
    }

    public function notifications(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $items = DB::table('notifications')
            ->where('user_id', $me->id)
            ->where('type', 'ministry_approval')
            ->orderByDesc('created_at')
            ->limit(100)
            ->get();

        return response()->json(['notifications' => $items]);
    }
}
