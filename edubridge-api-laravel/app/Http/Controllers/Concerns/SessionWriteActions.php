<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SessionWriteActions
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

            return response()->json(['session' => $this->normalizeSession($session)], 201);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إنشاء الجلسة'], 500);
        }
    }

    public function complete(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $session = DB::table('sessions')->where('id', $id)->first();

        if (!$session) {
            return response()->json(['error' => 'اجتماع الدعم غير موجود'], 404);
        }
        if (!$this->canAccess($user, $session) || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }
        if (($session->status ?? null) === 'cancelled') {
            return response()->json(['error' => 'لا يمكن إنهاء جلسة ملغية'], 409);
        }

        $mood = $request->input('mood_rating');
        if ($mood !== null && ((int) $mood < 1 || (int) $mood > 5)) {
            return response()->json(['error' => 'تقييم المشاركة التعليمية يجب أن يكون بين 1 و5'], 422);
        }

        $tags = $request->input('tags', []);
        if ($tags !== null && !is_array($tags)) {
            return response()->json(['error' => 'الوسوم يجب أن تكون قائمة'], 422);
        }

        try {
            DB::transaction(function () use ($request, $id, $session, $mood, $tags) {
                DB::table('sessions')->where('id', $id)->update([
                    'status' => 'done',
                    'completed_at' => now(),
                    'notes' => $request->input('notes'),
                    'recommendations' => $request->input('recommendations'),
                    'mood_rating' => $mood !== null ? (int) $mood : null,
                    'tags' => json_encode($tags ?? [], JSON_UNESCAPED_UNICODE),
                ]);

                if (!empty($session->learning_support_request_id)) {
                    DB::table('learning_support_requests')
                        ->where('id', $session->learning_support_request_id)
                        ->update([
                            'status' => 'completed',
                            'completed_at' => now(),
                            'updated_at' => now(),
                        ]);
                }
            });

            Notify::toChildParents(
                $session->child_id,
                'اكتملت جلسة الدعم التعليمي',
                'تم تسجيل جلسة الدعم التعليمي كمكتملة.',
                'learning_support_meeting_completed'
            );

            $fresh = $this->baseQuery()->where('s.id', $id)->first();
            return response()->json(['session' => $this->normalizeSession($fresh)]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إنهاء الجلسة'], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $session = DB::table('sessions')->where('id', $id)->first();
        if (!$session) {
            return response()->json(['error' => 'الجلسة غير موجودة'], 404);
        }
        if (!$this->canAccess($user, $session) || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $updates = [];
        if ($request->has('status')) {
            $status = (string) $request->input('status');
            $status = $status === 'completed' ? 'done' : $status;
            if (!in_array($status, self::DB_STATUSES, true)) {
                return response()->json(['error' => 'الحالة غير صالحة'], 422);
            }
            $updates['status'] = $status;
            if ($status === 'done') {
                $updates['completed_at'] = now();
            }
        }

        foreach (['scheduled_at', 'type', 'duration_minutes', 'notes', 'goals', 'recommendations', 'meeting_link'] as $field) {
            if ($request->has($field)) {
                $updates[$field] = $request->input($field);
            }
        }

        if ($request->has('tags')) {
            $tags = $request->input('tags');
            if (!is_array($tags)) {
                return response()->json(['error' => 'الوسوم يجب أن تكون قائمة'], 422);
            }
            $updates['tags'] = json_encode($tags, JSON_UNESCAPED_UNICODE);
        }
        if ($request->has('mood_rating')) {
            $updates['mood_rating'] = $request->input('mood_rating');
        }

        if ($updates) {
            DB::table('sessions')->where('id', $id)->update($updates);
        }

        $fresh = $this->baseQuery()->where('s.id', $id)->first();
        return response()->json(['session' => $this->normalizeSession($fresh)]);
    }
}
