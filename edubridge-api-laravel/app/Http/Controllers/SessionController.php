<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SessionController extends Controller
{
    private const DB_STATUSES = ['scheduled', 'done', 'cancelled'];
    private const TYPES = ['learningPlanning', 'followUp', 'parentReview', 'teamReview', 'groupSupport'];

    private function baseQuery()
    {
        return DB::table('sessions as s')
            ->join('children as c', 'c.id', '=', 's.child_id')
            ->leftJoin('users as u', 'u.id', '=', 's.specialist_id')
            ->select('s.*', 'c.name as child_name', 'u.name as specialist_name')
            ->orderByDesc('s.scheduled_at');
    }

    private function normalizeSession($session): array
    {
        $data = (array) $session;
        $data['status'] = ($data['status'] ?? 'scheduled') === 'done'
            ? 'completed'
            : ($data['status'] ?? 'scheduled');

        $tags = $data['tags'] ?? [];
        if (is_string($tags)) {
            $decoded = json_decode($tags, true);
            $tags = is_array($decoded) ? $decoded : [];
        }
        $data['tags'] = is_array($tags) ? array_values($tags) : [];
        $legacyTypes = [
            'initial' => 'learningPlanning',
            'crisis' => 'teamReview',
            'family' => 'parentReview',
            'group' => 'groupSupport',
        ];
        $rawType = $data['type'] ?? 'followUp';
        $data['type'] = $legacyTypes[$rawType] ?? $rawType;
        $data['duration_minutes'] = (int) ($data['duration_minutes'] ?? 45);

        return $data;
    }

    private function canAccess($user, $session): bool
    {
        if (!$user || !$session) {
            return false;
        }
        if ($user->role === 'admin') {
            return true;
        }
        if ($user->role === 'specialist') {
            return (int) $session->specialist_id === (int) $user->id;
        }
        if ($user->role === 'teacher') {
            return true;
        }
        if ($user->role === 'parent') {
            return DB::table('child_parent')
                ->where('child_id', $session->child_id)
                ->where('parent_id', $user->id)
                ->exists();
        }

        return false;
    }

    // GET /api/sessions and /api/therapy/sessions
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = $this->baseQuery();

            if ($user->role === 'specialist') {
                $query->where('s.specialist_id', $user->id);
            } elseif ($user->role === 'parent') {
                $query->join('child_parent as cp', 'cp.child_id', '=', 's.child_id')
                    ->where('cp.parent_id', $user->id);
            }

            if ($request->filled('child_id')) {
                $childId = (int) $request->query('child_id');
                if ($user->role === 'parent') {
                    $owns = DB::table('child_parent')
                        ->where('child_id', $childId)
                        ->where('parent_id', $user->id)
                        ->exists();
                    if (!$owns) {
                        return response()->json(['error' => 'غير مصرّح'], 403);
                    }
                }
                $query->where('s.child_id', $childId);
            }

            $sessions = $query->get()->map(fn ($s) => $this->normalizeSession($s));
            return response()->json(['sessions' => $sessions]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل الجلسات'], 500);
        }
    }

    public function byChild(Request $request, $childId)
    {
        $request->query->set('child_id', $childId);
        return $this->index($request);
    }

    // POST /api/sessions and /api/therapy/sessions
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
                'تم تحديد جلسة علاجية',
                'تمت إضافة جلسة علاجية جديدة. افتح الجلسات لعرض الموعد.',
                'therapy_session_scheduled'
            );

            return response()->json(['session' => $this->normalizeSession($session)], 201);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إنشاء الجلسة'], 500);
        }
    }

    // PUT /api/therapy/sessions/{id}/complete
    public function complete(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $session = DB::table('sessions')->where('id', $id)->first();

        if (!$session) {
            return response()->json(['error' => 'الجلسة غير موجودة'], 404);
        }
        if (!$this->canAccess($user, $session) || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }
        if (($session->status ?? null) === 'cancelled') {
            return response()->json(['error' => 'لا يمكن إنهاء جلسة ملغية'], 409);
        }

        $mood = $request->input('mood_rating');
        if ($mood !== null && ((int) $mood < 1 || (int) $mood > 5)) {
            return response()->json(['error' => 'التقييم النفسي يجب أن يكون بين 1 و5'], 422);
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

                if (!empty($session->therapy_request_id)) {
                    DB::table('therapy_requests')
                        ->where('id', $session->therapy_request_id)
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
                'therapy_session_completed'
            );

            $fresh = $this->baseQuery()->where('s.id', $id)->first();
            return response()->json(['session' => $this->normalizeSession($fresh)]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إنهاء الجلسة'], 500);
        }
    }

    // Legacy generic update route.
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
