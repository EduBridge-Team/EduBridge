<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait MinistryApprovalCreateActions
{
    public function store(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        if (!in_array($me->role, ['teacher','specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        $plan = trim((string) $request->input('educational_plan', ''));
        if ($childId <= 0 || $plan === '') {
            return response()->json(['error' => 'الطفل والخطة التعليمية مطلوبان'], 422);
        }

        if (!DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }
        if (!$this->canAccessChild($me, $childId)) {
            return response()->json(['error' => 'لا تملك صلاحية على هذا الطفل'], 403);
        }

        $teacherId = $request->input('teacher_id');
        if (
            $teacherId
            && !DB::table('users')->where('id', $teacherId)->where('role', 'teacher')->exists()
        ) {
            return response()->json(['error' => 'المعلّم غير موجود'], 422);
        }

        $methods = $request->input('teaching_methods', []);
        if (!is_array($methods)) {
            return response()->json(['error' => 'طرق التدريس يجب أن تكون قائمة'], 422);
        }

        try {
            $id = DB::table('ministry_approvals')->insertGetId([
                'child_id' => $childId,
                'evaluation_id' => $request->input('evaluation_id'),
                'submitted_by' => $me->id,
                'teacher_id' => $teacherId,
                'educational_plan' => $plan,
                'cognitive_assessment' => $request->input('cognitive_assessment'),
                'motor_assessment' => $request->input('motor_assessment'),
                'emotional_assessment' => $request->input('emotional_assessment'),
                'social_assessment' => $request->input('social_assessment'),
                'recommendations' => $request->input('recommendations'),
                'teaching_methods' => json_encode(array_values($methods), JSON_UNESCAPED_UNICODE),
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $ministryIds = DB::table('users')
                ->whereIn('role', ['ministry','admin'])
                ->pluck('id');

            foreach ($ministryIds as $userId) {
                Notify::toUser(
                    $userId,
                    'خطة تعليمية بانتظار المراجعة',
                    'تم إرسال خطة جديدة للمراجعة الوزارية.',
                    'ministry_approval'
                );
            }

            $row = $this->query()->where('a.id', $id)->first();

            return response()->json([
                'approval' => $this->normalize($row),
            ], 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر إرسال الخطة'], 500);
        }
    }
}
