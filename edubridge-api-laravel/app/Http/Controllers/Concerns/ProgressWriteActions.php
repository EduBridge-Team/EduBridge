<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ProgressWriteActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = (int) $request->input('child_id');
        $lessonId = $request->input('lesson_id');
        $status = $request->input('status');
        $score = $request->input('score');

        if (!$childId || !$lessonId) {
            return response()->json(['error' => 'child_id و lesson_id مطلوبان'], 400);
        }

        if (!$this->canAccessChild($user, $childId)) {
            return response()->json(['error' => 'لا تملك صلاحية تعديل تقدّم هذا الطفل'], 403);
        }

        if ($status && !in_array($status, ['not_started', 'in_progress', 'done'], true)) {
            return response()->json(['error' => 'الحالة غير صالحة'], 400);
        }

        $completedAt = $status === 'done' ? now() : null;

        try {
            DB::table('progress')->upsert(
                [[
                    'child_id' => $childId,
                    'lesson_id' => $lessonId,
                    'status' => $status ?: 'in_progress',
                    'score' => $score,
                    'completed_at' => $completedAt,
                ]],
                ['child_id', 'lesson_id'],
                ['status', 'score', 'completed_at']
            );

            $progress = DB::table('progress')
                ->where('child_id', $childId)
                ->where('lesson_id', $lessonId)
                ->first();

            return response()->json(['progress' => $progress], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
