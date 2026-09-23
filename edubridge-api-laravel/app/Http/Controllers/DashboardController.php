<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function stats(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user) {
            return response()->json(['error' => 'غير مصرّح'], 401);
        }

        try {
            $childIds = $this->visibleChildIds($user);

            $stats = [
                'children' => $childIds->count(),
                'lessons' => DB::table('lessons')->count(),
                'evaluations' => $childIds->isEmpty()
                    ? 0
                    : DB::table('evaluations')->whereIn('child_id', $childIds)->count(),
                'completed_progress' => $childIds->isEmpty()
                    ? 0
                    : DB::table('progress')
                        ->whereIn('child_id', $childIds)
                        ->where('status', 'done')
                        ->count(),
                'unread_notifications' => DB::table('notifications')
                    ->where('user_id', $user->id)
                    ->where('is_read', false)
                    ->count(),
            ];

            if (in_array($user->role, ['admin', 'ministry'], true)) {
                $stats['users'] = DB::table('users')->count();
            }

            return response()->json(['stats' => $stats]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    private function visibleChildIds($user)
    {
        if (in_array($user->role, ['admin', 'ministry', 'institution'], true)) {
            return DB::table('children')->pluck('id');
        }

        if ($user->role === 'parent') {
            return DB::table('child_parent')
                ->where('parent_id', $user->id)
                ->pluck('child_id')
                ->unique()
                ->values();
        }

        if ($user->role === 'teacher') {
            $teamIds = DB::table('child_teacher')
                ->where('teacher_id', $user->id)
                ->pluck('child_id');

            $primaryIds = DB::table('children')
                ->where('assigned_teacher_id', $user->id)
                ->pluck('id');

            return $teamIds->concat($primaryIds)->unique()->values();
        }

        if ($user->role === 'specialist') {
            return DB::table('child_specialist')
                ->where('specialist_id', $user->id)
                ->pluck('child_id')
                ->unique()
                ->values();
        }

        return collect();
    }
}
