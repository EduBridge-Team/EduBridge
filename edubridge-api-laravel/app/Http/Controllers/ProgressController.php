<?php

namespace App\Http\Controllers;

// مسارات التقدّم
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProgressController extends Controller
{
    // تسجيل/تحديث تقدّم الطفل بدرس (upsert)
    // POST /api/progress   body: { child_id, lesson_id, status, score }
    public function store(Request $request)
    {
        $childId = $request->input('child_id');
        $lessonId = $request->input('lesson_id');
        $status = $request->input('status');
        $score = $request->input('score');

        if (!$childId || !$lessonId) {
            return response()->json(['error' => 'child_id و lesson_id مطلوبان'], 400);
        }

        if ($status && !in_array($status, ['not_started', 'in_progress', 'done'])) {
            return response()->json(['error' => 'الحالة غير صالحة'], 400);
        }

        // إذا خلّص الدرس، نسجّل وقت الإتمام تلقائياً
        $completedAt = $status === 'done' ? now() : null;

        try {
            // إن وُجد السجل نحدّثه، وإلا نضيفه — upsert
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

    // عرض تقدّم طفل عبر كل الدروس (مع عنوان الدرس)
    // GET /api/progress/child/:childId
    public function byChild($childId)
    {
        try {
            $progress = DB::table('progress as p')
                ->join('lessons as l', 'l.id', '=', 'p.lesson_id')
                ->where('p.child_id', $childId)
                ->orderByRaw('p.completed_at DESC NULLS LAST')
                ->select('p.id', 'p.status', 'p.score', 'p.completed_at', 'l.id as lesson_id', 'l.title as lesson_title')
                ->get();

            return response()->json(['progress' => $progress]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // ملخّص تقدّم الطفل (عدد المكتمل / الجاري / المتبقّي + متوسّط النتيجة)
    // GET /api/progress/child/:childId/summary
    public function summary($childId)
    {
        try {
            $summary = DB::table('progress')
                ->where('child_id', $childId)
                ->selectRaw("
                    COUNT(*) FILTER (WHERE status = 'done')        AS done,
                    COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress,
                    COUNT(*) FILTER (WHERE status = 'not_started') AS not_started,
                    ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int AS avg_score
                ")
                ->first();

            return response()->json(['summary' => $summary]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
