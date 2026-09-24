<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CaseDiscussionReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['teacher','specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $query = $this->baseQuery()->orderByDesc('d.created_at');

        if ($user->role !== 'admin') {
            $query->where(function ($q) use ($user) {
                $q->where('d.created_by_id', $user->id)
                    ->orWhereIn('d.id', function ($sub) use ($user) {
                        $sub->from('case_discussion_participants')
                            ->select('discussion_id')
                            ->where('user_id', $user->id);
                    });
            });
        }

        if ($request->filled('child_id')) {
            $query->where('d.child_id', (int) $request->query('child_id'));
        }

        $rows = $query->get()->map(fn ($discussion) => $this->hydrate($discussion))->values();

        return response()->json(['discussions' => $rows]);
    }

    public function show(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $discussion = DB::table('case_discussions')->where('id', $id)->first();

        if (!$discussion) {
            return response()->json(['error' => 'دراسة الحالة غير موجودة'], 404);
        }
        if (!$this->canAccess($user, $discussion)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $row = $this->baseQuery()->where('d.id', $id)->first();

        return response()->json(['discussion' => $this->hydrate($row)]);
    }
}
