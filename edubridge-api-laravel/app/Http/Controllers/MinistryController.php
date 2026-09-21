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


    // قائمة كل المستخدمين للوزارة (عرض فقط — لا تعديل ولا حذف)
    // GET /api/ministry/users
    public function users(Request $request)
    {
        try {
            $users = DB::table('users')
                // لا نُرجع password_hash أبداً
                ->select('id', 'name', 'email', 'role', 'phone',
                    'verification_status', 'created_at')
                ->orderBy('name')
                ->get();

            return response()->json(['users' => $users]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // قائمة كل الأطفال للوزارة (عرض فقط)
    // GET /api/ministry/children
    public function children()
    {
        try {
            $children = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('users as tu', 'tu.id', '=', 'c.assigned_teacher_id')
                ->select('c.id', 'c.name', 'c.age', 'c.status', 'c.assigned_teacher_id',
                    'c.disability_type', 'dt.name as disability_name',
                    'tu.name as assigned_teacher_name')
                ->orderBy('c.name')
                ->get()
                ->map(function ($c) {
                    // للتوافق: لو ما فيه نوع إعاقة نصّي نستعمل اسم النوع من القائمة المرجعية
                    if (empty($c->disability_type) && !empty($c->disability_name)) {
                        $c->disability_type = $c->disability_name;
                    }
                    return $c;
                });

            return response()->json(['children' => $children]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إحصائيات شاملة للوحة الوزارة (البطاقة: نظرة عامة)
    // GET /api/ministry/stats
    public function stats()
    {
        try {
            return response()->json([
                'children_count' => DB::table('children')->count(),
                'users_count' => DB::table('users')->count(),
                // "الطلبات المعلّقة" = دروس بانتظار مراجعة المنهج من الوزارة
                'pending_approvals' => DB::table('lessons')->where('curriculum_status', 'pending')->count(),
                'schools_count' => DB::table('organizations')->count(),
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function statistics()
    {
        try {
            $byDisability = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->selectRaw("COALESCE(dt.name, 'غير محدد') as label, COUNT(*) as total")
                ->groupByRaw("COALESCE(dt.name, 'غير محدد')")
                ->pluck('total', 'label');

            $byAge = [
                '0-5' => DB::table('children')->whereBetween('age', [0, 5])->count(),
                '6-9' => DB::table('children')->whereBetween('age', [6, 9])->count(),
                '10-13' => DB::table('children')->whereBetween('age', [10, 13])->count(),
                '14+' => DB::table('children')->where('age', '>=', 14)->count(),
            ];

            $assignedTotal = 0;
            foreach (DB::table('homeworks')->get(['assigned_child_ids']) as $hw) {
                $ids = $hw->assigned_child_ids;
                if (is_string($ids)) {
                    $ids = json_decode($ids, true) ?: [];
                }
                if (is_array($ids)) $assignedTotal += count($ids);
            }
            $submitted = DB::table('homework_submissions')->count();
            $homeworkRate = $assignedTotal > 0 ? (int) round(($submitted / $assignedTotal) * 100) : 0;

            return response()->json([
                'total_children' => DB::table('children')->count(),
                'active_children' => DB::table('children')->whereIn('status', ['evaluated', 'assigned'])->count(),
                'homework_completion_rate' => min(100, $homeworkRate),
                'therapy_sessions_count' => DB::table('sessions')->count(),
                'by_disability_type' => $byDisability,
                'by_age_group' => $byAge,
            ]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function progressStatistics()
    {
        try {
            $rows = DB::table('progress')
                ->selectRaw("COUNT(*) FILTER (WHERE status = 'done') as completed")
                ->selectRaw("COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress")
                ->selectRaw("COUNT(*) FILTER (WHERE status = 'not_started') as not_started")
                ->selectRaw("COALESCE(ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int, 0) as average_score")
                ->first();

            return response()->json([
                'completed' => (int) ($rows->completed ?? 0),
                'in_progress' => (int) ($rows->in_progress ?? 0),
                'not_started' => (int) ($rows->not_started ?? 0),
                'average_score' => (int) ($rows->average_score ?? 0),
            ]);
        } catch (\Throwable $e) {
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
