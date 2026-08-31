<?php

namespace App\Http\Controllers;

// التقييمات — يُنشئها المعلّم/المختص، ويعرضها ولي الأمر ضمن تفاصيل الطفل
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EvaluationController extends Controller
{
    // فكّ ترميز أساليب التدريس المخزّنة كـ JSON
    private function decode($eval)
    {
        if ($eval && isset($eval->teaching_methods) && is_string($eval->teaching_methods)) {
            $eval->teaching_methods = json_decode($eval->teaching_methods, true);
        }
        return $eval;
    }

    // تقييمات طفل معيّن
    // GET /api/children/:childId/evaluations
    // GET /api/evaluations/child/:childId
    public function byChild($childId)
    {
        try {
            $evaluations = DB::table('evaluations as e')
                ->leftJoin('users as u', 'u.id', '=', 'e.evaluator_id')
                ->where('e.child_id', $childId)
                ->orderByDesc('e.created_at')
                ->select('e.*', 'u.name as evaluator_name')
                ->get()
                ->map(fn ($e) => $this->decode($e));

            return response()->json(['evaluations' => $evaluations]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إنشاء تقييم لطفل (معلّم / مختص / أدمن)
    // POST /api/evaluations/child/:childId
    public function store(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            if (!DB::table('children')->where('id', $childId)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
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
                'assigned_teacher_id' => $request->input('assigned_teacher_id'),
            ];
            if ($request->has('teaching_methods') && $request->input('teaching_methods') !== null) {
                $data['teaching_methods'] = json_encode($request->input('teaching_methods'), JSON_UNESCAPED_UNICODE);
            }

            $id = DB::table('evaluations')->insertGetId($data);

            // تحديث حالة الطفل: مُقيَّم، ومُعيَّن إن رافق التقييم تعيين معلّم
            $childUpdate = ['status' => 'evaluated'];
            if ($request->input('assigned_teacher_id')) {
                $childUpdate['assigned_teacher_id'] = $request->input('assigned_teacher_id');
                $childUpdate['status'] = 'assigned';
            }
            DB::table('children')->where('id', $childId)->update($childUpdate);

            // إشعار أولياء أمر الطفل بوجود تقييم جديد
            $this->notifyParents($childId);

            return response()->json(['evaluation' => $this->decode(DB::table('evaluations')->find($id))], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إشعار كل أولياء أمر الطفل بتقييم جديد
    private function notifyParents($childId)
    {
        try {
            $child = DB::table('children')->where('id', $childId)->first();
            $childName = $child->name ?? 'طفلك';

            $parentIds = DB::table('child_parent')
                ->where('child_id', $childId)
                ->pluck('parent_id');

            foreach ($parentIds as $pid) {
                DB::table('notifications')->insert([
                    'user_id' => $pid,
                    'title' => 'تقييم جديد',
                    'message' => "تم إضافة تقييم جديد للطفل $childName",
                    'type' => 'child_evaluated',
                ]);
            }
        } catch (\Exception $e) {
            report($e);
            // الإشعار ثانوي — لا نُفشل الطلب بسببه
        }
    }
}
