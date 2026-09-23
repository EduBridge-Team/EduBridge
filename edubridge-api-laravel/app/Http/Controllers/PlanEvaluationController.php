<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PlanEvaluationController extends Controller
{
    public function store(Request $request, $planId)
    {
        $me = $request->attributes->get('jwt_user');
        if (!in_array($me->role, ['specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        if ($childId <= 0 || !DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }
        if ($me->role === 'specialist'
            && !DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $me->id)
                ->exists()) {
            return response()->json(['error' => 'يمكنك تقييم خطط الأطفال ضمن فريقك فقط'], 403);
        }

        $appropriate = $request->input('is_plan_appropriate');
        if (!is_bool($appropriate) && !in_array($appropriate, [0,1,'0','1'], true)) {
            return response()->json(['error' => 'تقييم ملاءمة الخطة مطلوب'], 422);
        }

        $changes = $request->input('recommended_changes', []);
        if ($changes !== null && !is_array($changes)) {
            return response()->json(['error' => 'التغييرات المقترحة يجب أن تكون قائمة'], 422);
        }

        DB::table('plan_evaluations')->upsert([[
            'plan_id' => (int) $planId,
            'child_id' => $childId,
            'evaluator_id' => $me->id,
            'is_plan_appropriate' => filter_var($appropriate, FILTER_VALIDATE_BOOLEAN),
            'notes_for_teacher' => $request->input('notes_for_teacher'),
            'recommended_changes' => json_encode(array_values($changes ?? []), JSON_UNESCAPED_UNICODE),
            'created_at' => now(),
            'updated_at' => now(),
        ]], ['plan_id','child_id','evaluator_id'], [
            'is_plan_appropriate','notes_for_teacher','recommended_changes','updated_at'
        ]);

        $approval = DB::table('ministry_approvals')->where('id', $planId)->first();
        if ($approval && $approval->teacher_id) {
            Notify::toUser($approval->teacher_id, 'تقييم جديد للخطة',
                'أضاف المختص تقييماً على الخطة التعليمية.', 'plan_evaluation');
        }

        return response()->json([
            'evaluation' => DB::table('plan_evaluations')
                ->where('plan_id', $planId)
                ->where('child_id', $childId)
                ->where('evaluator_id', $me->id)
                ->first(),
        ], 201);
    }
}
