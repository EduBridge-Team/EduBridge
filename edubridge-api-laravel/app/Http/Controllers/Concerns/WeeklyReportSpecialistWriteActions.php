<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait WeeklyReportSpecialistWriteActions
{
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

        $specialistNotes = $this->specialistNotesPayload(
            $notes,
            $recommendations,
            $planEvaluation,
            $appropriate,
            $mood
        );
        $weekStart = now()->startOfWeek(Carbon::MONDAY)->startOfDay();
        $weekEnd = (clone $weekStart)->addDays(6)->endOfDay();

        try {
            $saved = $this->persistSpecialistWeeklyReport(
                $user,
                $childId,
                $weekStart,
                $weekEnd,
                $specialistNotes,
                $recommendations
            );

            Notify::toChildParents(
                $childId,
                'متابعة جديدة من المختص',
                'أضاف المختص متابعة جديدة إلى التقرير الأسبوعي للطفل.',
                'specialist_progress_created'
            );

            $row = $this->reportQuery()->where('wr.id', $saved['id'])->first();

            return response()->json([
                'report' => $this->enrich($this->normalize($row)),
            ], $saved['status']);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر حفظ متابعة المختص'], 500);
        }
    }
}
