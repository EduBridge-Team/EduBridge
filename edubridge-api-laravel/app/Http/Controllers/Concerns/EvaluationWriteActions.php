<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait EvaluationWriteActions
{
    public function store(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            if (!DB::table('children')->where('id', $childId)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            $assignedTeacherId = $request->input('assigned_teacher_id');
            if ($assignedTeacherId) {
                if (!in_array($user->role, ['specialist', 'admin'], true)) {
                    return response()->json(['error' => 'تعيين المعلّم من التقييم متاح للمختص والأدمن فقط'], 403);
                }
                if (!DB::table('users')->where('id', $assignedTeacherId)->where('role', 'teacher')->exists()) {
                    return response()->json(['error' => 'المعلّم غير موجود'], 422);
                }
            }

            $data = [
                'child_id' => $childId,
                'evaluator_id' => $user->id ?? null,
                'evaluation_type' => $request->input('evaluation_type'),
                'cognitive_assessment' => $request->input('cognitive_assessment'),
                'motor_assessment' => $request->input('motor_assessment'),
                'emotional_assessment' => $request->input('emotional_assessment'),
                'social_assessment' => $request->input('social_assessment'),
                'recommendations' => $request->input('recommendations'),
                'educational_plan' => $request->input('educational_plan'),
                'assigned_teacher_id' => $assignedTeacherId,
            ];

            if ($request->has('teaching_methods') && $request->input('teaching_methods') !== null) {
                $data['teaching_methods'] = json_encode(
                    $request->input('teaching_methods'),
                    JSON_UNESCAPED_UNICODE
                );
            }

            $id = DB::table('evaluations')->insertGetId($data);

            $childUpdate = ['status' => 'evaluated'];
            if ($assignedTeacherId) {
                $childUpdate['assigned_teacher_id'] = $assignedTeacherId;
                $childUpdate['status'] = 'assigned';

                DB::table('child_teacher')->insertOrIgnore([
                    'child_id' => $childId,
                    'teacher_id' => $assignedTeacherId,
                    'assigned_at' => now(),
                    'created_at' => now(),
                ]);
            }

            DB::table('children')->where('id', $childId)->update($childUpdate);

            $child = DB::table('children')->where('id', $childId)->first();

            Notify::toChildParents(
                $childId,
                'تقييم جديد',
                'تم إضافة تقييم جديد للطفل ' . ($child->name ?? 'طفلك'),
                'child_evaluated'
            );

            if ($assignedTeacherId) {
                Notify::toUser(
                    $assignedTeacherId,
                    'تقييم جديد للطفل',
                    'رفع المختص تقييماً للطفل "' . ($child->name ?? '') . '" — راجع الخطة وابدأ التنفيذ',
                    'evaluation_created'
                );
            }

            return response()->json([
                'evaluation' => $this->decode(DB::table('evaluations')->find($id)),
            ], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
