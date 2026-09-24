<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait WeeklyReportGeneralWriteActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['teacher','specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        if ($childId <= 0 || !DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }
        if (!$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'لا تملك صلاحية تعديل تقرير هذا الطفل'], 403);
        }

        try {
            $weekStart = Carbon::parse((string) $request->input('week_start'))->startOfDay();
        } catch (\Throwable $e) {
            return response()->json(['error' => 'بداية الأسبوع غير صالحة'], 422);
        }

        $weekEnd = (clone $weekStart)->addDays(6)->endOfDay();
        $progress = (int) $request->input('progress_percentage', 0);

        if ($progress < 0 || $progress > 100) {
            return response()->json(['error' => 'نسبة التقدم يجب أن تكون بين 0 و100'], 422);
        }

        $achievements = $request->input('achievements', []);
        $concerns = $request->input('concerns', []);

        if (!is_array($achievements) || !is_array($concerns)) {
            return response()->json(['error' => 'الإنجازات ونقاط الانتباه يجب أن تكون قوائم'], 422);
        }

        $existing = DB::table('weekly_reports')
            ->where('child_id', $childId)
            ->whereDate('week_start', $weekStart->toDateString())
            ->first();

        $payload = [
            'child_id' => $childId,
            'author_id' => $user->id,
            'week_start' => $weekStart,
            'week_end' => $weekEnd,
            'lessons_completed' => (int) $request->input('lessons_completed', 0),
            'progress_percentage' => $progress,
            'teacher_notes' => $request->input('teacher_notes'),
            'specialist_notes' => $request->input('specialist_notes'),
            'parent_notes' => $request->input('parent_notes'),
            'achievements' => json_encode(array_values($achievements), JSON_UNESCAPED_UNICODE),
            'concerns' => json_encode(array_values($concerns), JSON_UNESCAPED_UNICODE),
            'generated_at' => now(),
            'updated_at' => now(),
        ];

        try {
            if ($existing) {
                DB::table('weekly_reports')->where('id', $existing->id)->update($payload);
                $id = $existing->id;
            } else {
                $id = DB::table('weekly_reports')->insertGetId(array_merge($payload, [
                    'created_at' => now(),
                ]));
            }

            Notify::toChildParents(
                $childId,
                'تقرير أسبوعي جديد',
                'تم تحديث التقرير الأسبوعي للطفل.',
                'weekly_report_created'
            );

            $row = $this->reportQuery()->where('wr.id', $id)->first();

            return response()->json([
                'report' => $this->enrich($this->normalize($row)),
            ], $existing ? 200 : 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر حفظ التقرير الأسبوعي'], 500);
        }
    }
}
