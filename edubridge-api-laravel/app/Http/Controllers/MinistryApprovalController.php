<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MinistryApprovalController extends Controller
{
    private function query()
    {
        return DB::table('ministry_approvals as a')
            ->join('children as c', 'c.id', '=', 'a.child_id')
            ->leftJoin('users as s', 's.id', '=', 'a.submitted_by')
            ->leftJoin('users as t', 't.id', '=', 'a.teacher_id')
            ->select(
                'a.*',
                'c.name as child_name',
                's.name as submitted_by_name',
                't.name as teacher_name'
            )
            ->orderByDesc('a.created_at');
    }

    private function normalize($row): array
    {
        $data = (array) $row;
        $methods = $data['teaching_methods'] ?? [];
        if (is_string($methods)) {
            $decoded = json_decode($methods, true);
            $methods = is_array($decoded) ? $decoded : [];
        }
        $data['teaching_methods'] = array_values(is_array($methods) ? $methods : []);
        return $data;
    }

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

        $methods = $request->input('teaching_methods', []);
        if (!is_array($methods)) {
            return response()->json(['error' => 'طرق التدريس يجب أن تكون قائمة'], 422);
        }

        try {
            $id = DB::table('ministry_approvals')->insertGetId([
                'child_id' => $childId,
                'evaluation_id' => $request->input('evaluation_id'),
                'submitted_by' => $me->id,
                'teacher_id' => $request->input('teacher_id'),
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

            $ministryIds = DB::table('users')->whereIn('role', ['ministry','admin'])->pluck('id');
            foreach ($ministryIds as $uid) {
                Notify::toUser($uid, 'خطة تعليمية بانتظار المراجعة',
                    'تم إرسال خطة جديدة للمراجعة الوزارية.', 'ministry_approval');
            }

            $row = $this->query()->where('a.id', $id)->first();
            return response()->json(['approval' => $this->normalize($row)], 201);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إرسال الخطة'], 500);
        }
    }

    public function index(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $query = $this->query();

        if (!in_array($me->role, ['ministry','admin'], true)) {
            $query->where('a.submitted_by', $me->id);
        }

        $status = trim((string) $request->query('status', ''));
        if ($status !== '') {
            $statuses = array_values(array_filter(array_map('trim', explode(',', $status))));
            $valid = array_values(array_intersect($statuses, ['pending','approved','rejected']));
            if ($valid) $query->whereIn('a.status', $valid);
        }

        return response()->json([
            'approvals' => $query->get()->map(fn ($r) => $this->normalize($r))->values(),
        ]);
    }

    public function pending(Request $request)
    {
        $request->query->set('status', 'pending');
        return $this->index($request);
    }

    public function approve(Request $request, $id)
    {
        return $this->review($request, (int) $id, 'approved');
    }

    public function reject(Request $request, $id)
    {
        return $this->review($request, (int) $id, 'rejected');
    }

    private function review(Request $request, int $id, string $status)
    {
        $me = $request->attributes->get('jwt_user');
        $approval = DB::table('ministry_approvals')->where('id', $id)->first();
        if (!$approval) return response()->json(['error' => 'الطلب غير موجود'], 404);

        DB::table('ministry_approvals')->where('id', $id)->update([
            'status' => $status,
            'review_reason' => $status === 'rejected' ? $request->input('reason') : null,
            'reviewed_by' => $me->id,
            'reviewed_at' => now(),
            'updated_at' => now(),
        ]);

        if ($status === 'approved' && $approval->teacher_id) {
            DB::table('children')->where('id', $approval->child_id)->update([
                'assigned_teacher_id' => $approval->teacher_id,
                'status' => 'assigned',
            ]);
            DB::table('child_teacher')->insertOrIgnore([
                'child_id' => $approval->child_id,
                'teacher_id' => $approval->teacher_id,
                'assigned_at' => now(),
                'created_at' => now(),
            ]);
        }

        $title = $status === 'approved' ? 'تم اعتماد الخطة' : 'تم رفض الخطة';
        $message = $status === 'approved'
            ? 'اعتمدت الوزارة الخطة التعليمية.'
            : 'تم رفض الخطة التعليمية' . ($request->input('reason') ? ': ' . $request->input('reason') : '.');

        Notify::toUser($approval->submitted_by, $title, $message, 'ministry_approval');
        if ($approval->teacher_id) Notify::toUser($approval->teacher_id, $title, $message, 'ministry_approval');
        Notify::toChildParents($approval->child_id, $title, $message, 'ministry_approval');

        $row = $this->query()->where('a.id', $id)->first();
        return response()->json(['approval' => $this->normalize($row)]);
    }

    public function childStatus($childId)
    {
        $row = DB::table('ministry_approvals')
            ->where('child_id', $childId)
            ->orderByDesc('created_at')
            ->first();

        return response()->json(['status' => $row->status ?? 'none']);
    }

    public function notifications(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $items = DB::table('notifications')
            ->where('user_id', $me->id)
            ->where('type', 'ministry_approval')
            ->orderByDesc('created_at')
            ->limit(100)
            ->get();

        return response()->json(['notifications' => $items]);
    }
}
