<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SessionCreateActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        $scheduledAt = trim((string) $request->input('scheduled_at', ''));
        $type = (string) $request->input('type', 'followUp');
        $duration = (int) $request->input('duration_minutes', 45);

        if ($childId <= 0 || $scheduledAt === '') {
            return response()->json(['error' => 'child_id و scheduled_at مطلوبان'], 422);
        }
        if (!in_array($type, self::TYPES, true)) {
            return response()->json(['error' => 'نوع الجلسة غير صالح'], 422);
        }
        if ($duration < 10 || $duration > 240) {
            return response()->json(['error' => 'مدة الجلسة غير صالحة'], 422);
        }

        $specialistId = $user->role === 'admin'
            ? (int) ($request->input('specialist_id') ?: $user->id)
            : (int) $user->id;

        if (!DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }
        if ($user->role === 'specialist' && !$this->canAccessChild($user, $childId)) {
            return response()->json(['error' => 'يمكنك إنشاء جلسات فقط للأطفال ضمن فريقك'], 403);
        }
        if (!DB::table('users')->where('id', $specialistId)->where('role', 'specialist')->exists()) {
            return response()->json(['error' => 'المختص غير موجود'], 404);
        }

        try {
            $id = DB::table('sessions')->insertGetId([
                'specialist_id' => $specialistId,
                'child_id' => $childId,
                'type' => $type,
                'scheduled_at' => $scheduledAt,
                'duration_minutes' => $duration,
                'goals' => $request->input('goals'),
                'meeting_link' => $request->input('meeting_link'),
                'status' => 'scheduled',
            ]);

            $session = $this->baseQuery()->where('s.id', $id)->first();

            Notify::toChildParents(
                $childId,
                'تم تحديد اجتماع دعم تعليمي',
                'تمت إضافة جلسة دعم تعليمي جديدة. افتح اجتماعات الدعم لعرض الموعد.',
                'learning_support_meeting_scheduled'
            );

            return response()->json([
                'session' => $this->normalizeSession($session),
            ], 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر إنشاء الجلسة'], 500);
        }
    }
}
