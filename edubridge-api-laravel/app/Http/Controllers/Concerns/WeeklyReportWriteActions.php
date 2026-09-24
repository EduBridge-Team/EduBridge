<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait WeeklyReportWriteActions
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

    public function storeSpecialist(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        if ($childId <= 0 || !DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }
        if (!$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'لا تملك صلاحية تعديل تقرير هذا الطفل'], 403);
        }

        $notes = trim((string) $request->input('specialist_notes', ''));
        $recommendations = trim((string) $request->input('recommendations', ''));
        $planEvaluation = trim((string) $request->input('plan_evaluation', ''));
        $appropriate = $request->input('is_plan_appropriate');
        $mood = $request->input('mood_rating');

        if ($notes === '') {
            return response()->json(['error' => 'ملاحظات المختص مطلوبة'], 422);
        }
        if ($mood !== null && ((int) $mood < 1 || (int) $mood > 5)) {
            return response()->json(['error' => 'تقييم التفاعل يجب أن يكون بين 1 و5'], 422);
        }

        $sections = [$notes];
        if ($recommendations !== '') {
            $sections[] = 'التوصيات: ' . $recommendations;
        }
        if ($appropriate !== null) {
            $isAppropriate = filter_var($appropriate, FILTER_VALIDATE_BOOLEAN);
            $sections[] = 'ملاءمة الخطة: ' . ($isAppropriate ? 'مناسبة' : 'تحتاج تعديلاً');
        }
        if ($planEvaluation !== '') {
            $sections[] = 'تقييم الخطة: ' . $planEvaluation;
        }
        if ($mood !== null) {
            $sections[] = 'تقييم التفاعل: ' . (int) $mood . '/5';
        }
        $specialistNotes = implode("\n", $sections);

        $weekStart = now()->startOfWeek(Carbon::MONDAY)->startOfDay();
        $weekEnd = (clone $weekStart)->addDays(6)->endOfDay();

        try {
            $existing = DB::table('weekly_reports')
                ->where('child_id', $childId)
                ->whereDate('week_start', $weekStart->toDateString())
                ->first();

            if ($existing) {
                DB::table('weekly_reports')->where('id', $existing->id)->update([
                    'specialist_notes' => $specialistNotes,
                    'updated_at' => now(),
                ]);
                $id = $existing->id;
                $status = 200;
            } else {
                $id = DB::table('weekly_reports')->insertGetId([
                    'child_id' => $childId,
                    'author_id' => $user->id,
                    'week_start' => $weekStart,
                    'week_end' => $weekEnd,
                    'lessons_completed' => 0,
                    'progress_percentage' => 0,
                    'specialist_notes' => $specialistNotes,
                    'achievements' => json_encode([], JSON_UNESCAPED_UNICODE),
                    'concerns' => json_encode(
                        $recommendations !== '' ? [$recommendations] : [],
                        JSON_UNESCAPED_UNICODE
                    ),
                    'generated_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                $status = 201;
            }

            Notify::toChildParents(
                $childId,
                'متابعة جديدة من المختص',
                'أضاف المختص متابعة جديدة إلى التقرير الأسبوعي للطفل.',
                'specialist_progress_created'
            );

            $row = $this->reportQuery()->where('wr.id', $id)->first();
            return response()->json([
                'report' => $this->enrich($this->normalize($row)),
            ], $status);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حفظ متابعة المختص'], 500);
        }
    }
}
