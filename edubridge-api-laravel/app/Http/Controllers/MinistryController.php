<?php

namespace App\Http\Controllers;

// مراجعة المناهج من الوزارة (البطاقة 3)
// حساب "وزارة" يراجع الدروس ويعتمدها/يرفضها بمطابقتها للمنهج المعتمد لكل مستوى.
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;

class MinistryController extends Controller
{
    // قائمة الدروس للمراجعة، مع فلترة اختيارية ?status=pending|approved|rejected
    // GET /api/ministry/lessons
    public function lessons(Request $request)
    {
        try {
            $query = DB::table('lessons as l')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'l.disability_type_id')
                ->leftJoin('users as t', 't.id', '=', 'l.teacher_id')
                ->select('l.*', 'dt.name as disability_name', 't.name as teacher_name')
                ->orderByDesc('l.created_at');

            $status = $request->query('status');
            if ($status && in_array($status, ['pending', 'approved', 'rejected'], true)) {
                $query->where('l.curriculum_status', $status);
            }
            if ($request->query('education_level')) {
                $query->where('l.education_level', $request->query('education_level'));
            }

            return response()->json(['lessons' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // اعتماد/رفض درس (وزارة)
    // PUT /api/ministry/lessons/:id   body: { status: approved|rejected, note? }
    public function review(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');

        $status = $request->input('status');
        if (!in_array($status, ['approved', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون approved أو rejected'], 400);
        }

        try {
            $lesson = DB::table('lessons')->where('id', $id)->first();
            if (!$lesson) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }

            DB::table('lessons')->where('id', $id)->update([
                'curriculum_status' => $status,
                'review_note' => $request->input('note'),
                'reviewed_by' => $me->id,
                'reviewed_at' => now(),
            ]);

            // إشعار مُعدّ الدرس (المعلّم) بنتيجة المراجعة
            if ($lesson->teacher_id) {
                Notify::toUser(
                    $lesson->teacher_id,
                    $status === 'approved' ? 'تم اعتماد الدرس' : 'تم رفض الدرس',
                    ($status === 'approved'
                        ? 'اعتمدت الوزارة الدرس: '
                        : 'رفضت الوزارة الدرس: ') . $lesson->title
                        . ($request->input('note') ? ' — ' . $request->input('note') : ''),
                    'curriculum_review'
                );
            }

            return response()->json(['lesson' => DB::table('lessons')->find($id)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
