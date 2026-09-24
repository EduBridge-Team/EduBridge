<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LearningSupportRecommendationActions
{
    public function recommendToParent(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        $reason = trim((string) $request->input('reason', ''));
        $description = trim((string) $request->input('description', ''));
        $urgency = (string) $request->input('urgency', 'medium');

        if ($childId <= 0 || !DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }
        if ($reason === '') {
            return response()->json(['error' => 'سبب التوصية مطلوب'], 422);
        }
        if ($description === '' || mb_strlen($description) < 15 || mb_strlen($description) > 1000) {
            return response()->json(['error' => 'الشرح يجب أن يكون بين 15 و1000 حرف'], 422);
        }
        if (!in_array($urgency, ['low', 'medium', 'high'], true)) {
            return response()->json(['error' => 'درجة الأهمية غير صالحة'], 422);
        }

        $childName = (string) (DB::table('children')->where('id', $childId)->value('name') ?? '');
        $urgencyLabel = [
            'low' => 'منخفضة',
            'medium' => 'متوسطة',
            'high' => 'عالية',
        ][$urgency];

        Notify::toChildParents(
            $childId,
            'توصية بدعم تعليمي',
            "أوصى المختص بمتابعة دعم تعليمي للطفل {$childName}. السبب: {$reason}. الأهمية: {$urgencyLabel}. {$description}",
            'learning_support_recommendation'
        );

        return response()->json([
            'ok' => true,
            'recommendation' => [
                'child_id' => $childId,
                'reason' => $reason,
                'description' => $description,
                'urgency' => $urgency,
            ],
        ], 201);
    }
}
