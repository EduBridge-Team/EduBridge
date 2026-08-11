<?php

namespace App\Http\Controllers;

// جلسات المختص مع الطفل (مواعيد المتابعة العلاجية)
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SessionController extends Controller
{
    private const STATUSES = ['scheduled', 'done', 'cancelled'];

    // استعلام أساسي مع اسم الطفل واسم المختص
    private function baseQuery()
    {
        return DB::table('sessions as s')
            ->join('children as c', 'c.id', '=', 's.child_id')
            ->leftJoin('users as u', 'u.id', '=', 's.specialist_id')
            ->select('s.*', 'c.name as child_name', 'u.name as specialist_name')
            ->orderByDesc('s.scheduled_at');
    }

    // عرض الجلسات — المختص يرى جلساته، والأدمن يرى الكل
    // GET /api/sessions?child_id=
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = $this->baseQuery();

            if ($user->role === 'specialist') {
                $query->where('s.specialist_id', $user->id);
            }
            if ($request->query('child_id')) {
                $query->where('s.child_id', $request->query('child_id'));
            }

            return response()->json(['sessions' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // جلسات طفل معيّن
    // GET /api/sessions/child/:childId
    public function byChild($childId)
    {
        try {
            $sessions = $this->baseQuery()->where('s.child_id', $childId)->get();
            return response()->json(['sessions' => $sessions]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إنشاء جلسة (مختص / أدمن)
    // POST /api/sessions   body: { child_id, scheduled_at, status?, specialist_id? }
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = $request->input('child_id');
        $scheduledAt = $request->input('scheduled_at');

        if (!$childId || !$scheduledAt) {
            return response()->json(['error' => 'child_id و scheduled_at مطلوبان'], 400);
        }

        $status = $request->input('status') ?: 'scheduled';
        if (!in_array($status, self::STATUSES, true)) {
            return response()->json(['error' => 'الحالة غير صالحة'], 400);
        }

        // المختص يُنشئ لنفسه؛ الأدمن قد يحدّد المختص
        $specialistId = $user->role === 'admin'
            ? ($request->input('specialist_id') ?: $user->id)
            : $user->id;

        try {
            if (!DB::table('children')->where('id', $childId)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            $id = DB::table('sessions')->insertGetId([
                'specialist_id' => $specialistId,
                'child_id' => $childId,
                'scheduled_at' => $scheduledAt,
                'status' => $status,
            ]);

            return response()->json(['session' => DB::table('sessions')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تحديث جلسة — الحالة و/أو الموعد (مختص / أدمن)
    // PUT /api/sessions/:id   body: { status?, scheduled_at? }
    public function update(Request $request, $id)
    {
        try {
            if (!DB::table('sessions')->where('id', $id)->exists()) {
                return response()->json(['error' => 'الجلسة غير موجودة'], 404);
            }

            $updates = [];
            if ($request->has('status')) {
                $status = $request->input('status');
                if (!in_array($status, self::STATUSES, true)) {
                    return response()->json(['error' => 'الحالة غير صالحة'], 400);
                }
                $updates['status'] = $status;
            }
            if ($request->has('scheduled_at')) {
                $updates['scheduled_at'] = $request->input('scheduled_at');
            }

            if (!empty($updates)) {
                DB::table('sessions')->where('id', $id)->update($updates);
            }

            return response()->json(['session' => DB::table('sessions')->find($id)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
