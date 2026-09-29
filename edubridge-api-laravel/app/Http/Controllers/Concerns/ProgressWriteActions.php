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
            $result = DB::transaction(function () use (
                $childId,
                $lessonId,
                $status,
                $score,
                $completedAt
            ) {
                $existing = DB::table('progress')
                    ->where('child_id', $childId)
                    ->where('lesson_id', $lessonId)
                    ->lockForUpdate()
                    ->first();

                $firstCompletion = $status === 'done'
                    && (!$existing || $existing->status !== 'done');

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

                if ($firstCompletion) {
                    $reward = DB::table('child_rewards')
                        ->where('child_id', $childId)
                        ->lockForUpdate()
                        ->first();

                    if ($reward) {
                        DB::table('child_rewards')
                            ->where('child_id', $childId)
                            ->update([
                                'stars' => (int) $reward->stars + 1,
                                'updated_at' => now(),
                            ]);
                    } else {
                        DB::table('child_rewards')->insert([
                            'child_id' => $childId,
                            'stars' => 1,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    }
                }

                return [
                    'progress' => DB::table('progress')
                        ->where('child_id', $childId)
                        ->where('lesson_id', $lessonId)
                        ->first(),
                    'rewarded_star' => $firstCompletion,
                    'stars' => (int) (
                        DB::table('child_rewards')
                            ->where('child_id', $childId)
                            ->value('stars') ?? 0
                    ),
                ];
            });

            return response()->json($result, 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
