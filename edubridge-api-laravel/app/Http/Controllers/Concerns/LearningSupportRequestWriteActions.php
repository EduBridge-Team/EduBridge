<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LearningSupportRequestWriteActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || $user->role !== 'parent') {
            return response()->json(['error' => 'هذه العملية متاحة لولي الأمر فقط'], 403);
        }

        $childId = (int) $request->input('child_id');
        $reason = trim((string) $request->input('reason', ''));
        $description = trim((string) $request->input('description', ''));
        $urgency = (string) $request->input('urgency', 'medium');

        if ($childId <= 0 || !$this->parentOwnsChild((int) $user->id, $childId)) {
            return response()->json(['error' => 'الطفل غير موجود أو غير مرتبط بحسابك'], 403);
        }
        if ($reason === '') {
            return response()->json(['error' => 'السبب الرئيسي مطلوب'], 422);
        }
        if (mb_strlen($reason) > 160) {
            return response()->json(['error' => 'السبب طويل جداً'], 422);
        }
        if ($description !== '' && mb_strlen($description) > 1000) {
            return response()->json(['error' => 'الشرح طويل جداً'], 422);
        }
        if (!in_array($urgency, ['low', 'medium', 'high'], true)) {
            return response()->json(['error' => 'درجة الأهمية غير صالحة'], 422);
        }

        $duplicate = DB::table('learning_support_requests')
            ->where('child_id', $childId)
            ->where('parent_id', $user->id)
            ->whereIn('status', ['pending', 'scheduled'])
            ->exists();

        if ($duplicate) {
            return response()->json([
                'error' => 'يوجد طلب دعم تعليمي مفتوح لهذا الطفل بالفعل',
            ], 409);
        }

        try {
            $id = DB::table('learning_support_requests')->insertGetId([
                'child_id' => $childId,
                'parent_id' => $user->id,
                'reason' => $reason,
                'description' => $description !== '' ? $description : null,
                'urgency' => $urgency,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $childName = (string) (DB::table('children')
                ->where('id', $childId)
                ->value('name') ?? '');

            $specialistIds = DB::table('users')
                ->where('role', 'specialist')
                ->pluck('id');

            foreach ($specialistIds as $specialistId) {
                Notify::toUser(
                    $specialistId,
                    'طلب دعم تعليمي جديد',
                    "وصل طلب جلسة دعم تعليمي جديد للطفل {$childName}",
                    'learning_support_request_created'
                );
            }

            $created = $this->requestQuery()->where('tr.id', $id)->first();

            return response()->json(['request' => $created], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'تعذّر إرسال الطلب حالياً'], 500);
        }
    }

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
