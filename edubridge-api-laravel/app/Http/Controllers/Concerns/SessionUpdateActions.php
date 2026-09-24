<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SessionUpdateActions
{
    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $session = DB::table('sessions')->where('id', $id)->first();

        if (!$session) {
            return response()->json(['error' => 'الجلسة غير موجودة'], 404);
        }
        if (!$this->canAccess($user, $session) || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $updates = [];

        if ($request->has('status')) {
            $status = (string) $request->input('status');
            $status = $status === 'completed' ? 'done' : $status;

            if (!in_array($status, self::DB_STATUSES, true)) {
                return response()->json(['error' => 'الحالة غير صالحة'], 422);
            }

            $updates['status'] = $status;

            if ($status === 'done') {
                $updates['completed_at'] = now();
            }
        }

        foreach (
            ['scheduled_at', 'type', 'duration_minutes', 'notes', 'goals', 'recommendations', 'meeting_link']
            as $field
        ) {
            if ($request->has($field)) {
                $updates[$field] = $request->input($field);
            }
        }

        if ($request->has('tags')) {
            $tags = $request->input('tags');

            if (!is_array($tags)) {
                return response()->json(['error' => 'الوسوم يجب أن تكون قائمة'], 422);
            }

            $updates['tags'] = json_encode($tags, JSON_UNESCAPED_UNICODE);
        }

        if ($request->has('mood_rating')) {
            $updates['mood_rating'] = $request->input('mood_rating');
        }

        if ($updates) {
            DB::table('sessions')->where('id', $id)->update($updates);
        }

        $fresh = $this->baseQuery()->where('s.id', $id)->first();

        return response()->json([
            'session' => $this->normalizeSession($fresh),
        ]);
    }
}
