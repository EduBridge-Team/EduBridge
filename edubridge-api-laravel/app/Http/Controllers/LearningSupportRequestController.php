<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LearningSupportRequestController extends Controller
{
    private function requestQuery()
    {
        return DB::table('learning_support_requests as tr')
            ->join('children as c', 'c.id', '=', 'tr.child_id')
            ->join('users as p', 'p.id', '=', 'tr.parent_id')
            ->leftJoin('users as s', 's.id', '=', 'tr.specialist_id')
            ->select(
                'tr.*',
                'c.name as child_name',
                'p.name as parent_name',
                's.name as specialist_name'
            );
    }

    private function parentOwnsChild(int $parentId, int $childId): bool
    {
        return DB::table('child_parent')
            ->where('parent_id', $parentId)
            ->where('child_id', $childId)
            ->exists();
    }

    private function canViewChild($user, int $childId): bool
    {
        if (!$user) {
            return false;
        }

        if (in_array($user->role, ['specialist', 'admin'], true)) {
            return true;
        }

        return $user->role === 'parent'
            && $this->parentOwnsChild((int) $user->id, $childId);
    }

    // ولي الأمر ينشئ طلب جلسة دعم تعليمي لطفل مرتبط بحسابه.
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || $user->role !== 'parent') {
            return response()->json(['error' => 'هذه العملية متاحة لولي الأمر فقط'], 403);
        }

        $childId = (int) $request->input('child_id');
        $reason = trim((string) $request->input('reason', ''));
        $description = trim((string) $request->input('description', ''));
        $urgency = (string) $request->input('urgency', 'medium');

        if ($childId <= 0 || !$this->parentOwnsChild((int) $user->id, $childId)) {
            return response()->json(['error' => 'الطفل غير موجود أو غير مرتبط بحسابك'], 403);
        }
        if ($reason === '') {
            return response()->json(['error' => 'السبب الرئيسي مطلوب'], 422);
        }
        if (mb_strlen($reason) > 160) {
            return response()->json(['error' => 'السبب طويل جداً'], 422);
        }
        if ($description !== '' && mb_strlen($description) > 1000) {
            return response()->json(['error' => 'الشرح طويل جداً'], 422);
        }
        if (!in_array($urgency, ['low', 'medium', 'high'], true)) {
            return response()->json(['error' => 'درجة الأهمية غير صالحة'], 422);
        }

        $duplicate = DB::table('learning_support_requests')
            ->where('child_id', $childId)
            ->where('parent_id', $user->id)
            ->whereIn('status', ['pending', 'scheduled'])
            ->exists();
        if ($duplicate) {
            return response()->json([
                'error' => 'يوجد طلب دعم تعليمي مفتوح لهذا الطفل بالفعل',
            ], 409);
        }

        try {
            $id = DB::table('learning_support_requests')->insertGetId([
                'child_id' => $childId,
                'parent_id' => $user->id,
                'reason' => $reason,
                'description' => $description !== '' ? $description : null,
                'urgency' => $urgency,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $childName = (string) (DB::table('children')->where('id', $childId)->value('name') ?? '');

            $specialistIds = DB::table('users')
                ->where('role', 'specialist')
                ->pluck('id');
            foreach ($specialistIds as $specialistId) {
                Notify::toUser(
                    $specialistId,
                    'طلب دعم تعليمي جديد',
                    "وصل طلب جلسة دعم تعليمي جديد للطفل {$childName}",
                    'learning_support_request_created'
                );
            }

            $created = $this->requestQuery()->where('tr.id', $id)->first();
            return response()->json(['request' => $created], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إرسال الطلب حالياً'], 500);
        }
    }

    // المختص/الأدمن يرى كل الطلبات، وولي الأمر يرى طلباته فقط.
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['parent', 'specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $query = $this->requestQuery()->orderByDesc('tr.created_at');

            if ($user->role === 'parent') {
                $query->where('tr.parent_id', $user->id);
            }

            if ($request->filled('child_id')) {
                $childId = (int) $request->query('child_id');
                if (!$this->canViewChild($user, $childId)) {
                    return response()->json(['error' => 'غير مصرّح'], 403);
                }
                $query->where('tr.child_id', $childId);
            }

            if ($request->filled('status')) {
                $status = (string) $request->query('status');
                if (!in_array($status, ['pending', 'scheduled', 'completed', 'cancelled'], true)) {
                    return response()->json(['error' => 'الحالة غير صالحة'], 422);
                }
                $query->where('tr.status', $status);
            }

            return response()->json(['requests' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل الطلبات'], 500);
        }
    }

    public function pendingForChild(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = (int) $childId;
        if (!$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $query = DB::table('learning_support_requests')
            ->where('child_id', $childId)
            ->whereIn('status', ['pending', 'scheduled']);

        if ($user->role === 'parent') {
            $query->where('parent_id', $user->id);
        }

        return response()->json(['has_pending' => $query->exists()]);
    }

    private function upsertSessionForRequest($learningSupportRequest, int $specialistId, $scheduledAt, string $meetingLink, ?string $notes): void
    {
        $payload = [
            'specialist_id' => $specialistId,
            'child_id' => $learningSupportRequest->child_id,
            'learning_support_request_id' => $learningSupportRequest->id,
            'type' => 'learningPlanning',
            'scheduled_at' => $scheduledAt,
            'duration_minutes' => 45,
            'meeting_link' => $meetingLink,
            'notes' => $notes,
            'status' => 'scheduled',
        ];

        $existingId = DB::table('sessions')
            ->where('learning_support_request_id', $learningSupportRequest->id)
            ->value('id');

        if ($existingId) {
            DB::table('sessions')->where('id', $existingId)->update($payload);
        } else {
            DB::table('sessions')->insert($payload);
        }
    }

    // المختص يحدد الموعد ورابط الاجتماع، ويصبح هو المختص المسؤول عن الطلب.
    public function schedule(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $scheduledRaw = trim((string) $request->input('scheduled_at', ''));
        $meetingLink = trim((string) $request->input('meeting_link', ''));
        $notes = trim((string) $request->input('specialist_notes', ''));

        if ($scheduledRaw === '' || $meetingLink === '') {
            return response()->json(['error' => 'التاريخ ورابط الاجتماع مطلوبان'], 422);
        }
        if (!filter_var($meetingLink, FILTER_VALIDATE_URL)) {
            return response()->json(['error' => 'رابط الاجتماع غير صالح'], 422);
        }

        try {
            $scheduledAt = Carbon::parse($scheduledRaw);
        } catch (\Throwable $e) {
            return response()->json(['error' => 'صيغة الموعد غير صالحة'], 422);
        }
        if ($scheduledAt->isPast()) {
            return response()->json(['error' => 'يجب اختيار موعد قادم'], 422);
        }

        $learningSupportRequest = DB::table('learning_support_requests')->where('id', $id)->first();
        if (!$learningSupportRequest) {
            return response()->json(['error' => 'الطلب غير موجود'], 404);
        }
        if (in_array($learningSupportRequest->status, ['completed', 'cancelled'], true)) {
            return response()->json(['error' => 'لا يمكن جدولة طلب منتهٍ'], 409);
        }
        if ($learningSupportRequest->specialist_id
            && (int) $learningSupportRequest->specialist_id !== (int) $user->id
            && $user->role !== 'admin') {
            return response()->json(['error' => 'هذا الطلب يتابعه مختص آخر'], 409);
        }

        $assignedSpecialistId = $user->role === 'specialist'
            ? (int) $user->id
            : (int) ($request->input('specialist_id') ?: ($learningSupportRequest->specialist_id ?: 0));

        if ($assignedSpecialistId <= 0
            || !DB::table('users')->where('id', $assignedSpecialistId)->where('role', 'specialist')->exists()) {
            return response()->json(['error' => 'يجب تحديد مختص دعم تعليمي صالح للاجتماع'], 422);
        }

        try {
            DB::transaction(function () use ($id, $learningSupportRequest, $assignedSpecialistId, $scheduledAt, $meetingLink, $notes) {
                DB::table('learning_support_requests')->where('id', $id)->update([
                    'specialist_id' => $assignedSpecialistId,
                    'scheduled_at' => $scheduledAt,
                    'meeting_link' => $meetingLink,
                    'specialist_notes' => $notes !== '' ? $notes : null,
                    'status' => 'scheduled',
                    'updated_at' => now(),
                ]);

                $this->upsertSessionForRequest(
                    $learningSupportRequest,
                    $assignedSpecialistId,
                    $scheduledAt,
                    $meetingLink,
                    $notes !== '' ? $notes : null
                );
            });

            $childName = (string) (DB::table('children')->where('id', $learningSupportRequest->child_id)->value('name') ?? '');
            Notify::toChildParents(
                $learningSupportRequest->child_id,
                'تم تحديد موعد جلسة الدعم التعليمي',
                "تم تحديد موعد جلسة الدعم التعليمي للطفل {$childName}. افتح الطلب لعرض الموعد والرابط.",
                'learning_support_meeting_scheduled'
            );

            return response()->json([
                'request' => $this->requestQuery()->where('tr.id', $id)->first(),
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حفظ الموعد'], 500);
        }
    }

    public function complete(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $learningSupportRequest = DB::table('learning_support_requests')->where('id', $id)->first();
        if (!$learningSupportRequest) {
            return response()->json(['error' => 'الطلب غير موجود'], 404);
        }
        if ($learningSupportRequest->status !== 'scheduled') {
            return response()->json(['error' => 'يمكن إنهاء اجتماع الدعم بعد جدولته فقط'], 409);
        }
        if ($learningSupportRequest->specialist_id
            && (int) $learningSupportRequest->specialist_id !== (int) $user->id
            && $user->role !== 'admin') {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::transaction(function () use ($id) {
            DB::table('learning_support_requests')->where('id', $id)->update([
                'status' => 'completed',
                'completed_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('sessions')->where('learning_support_request_id', $id)->update([
                'status' => 'done',
                'completed_at' => now(),
            ]);
        });

        Notify::toChildParents(
            $learningSupportRequest->child_id,
            'اكتملت جلسة الدعم التعليمي',
            'تم تسجيل جلسة الدعم التعليمي كمكتملة.',
            'learning_support_meeting_completed'
        );

        return response()->json([
            'request' => $this->requestQuery()->where('tr.id', $id)->first(),
        ]);
    }

    // ولي الأمر يستطيع إلغاء طلبه ما دام قيد المراجعة، والمختص/الأدمن يستطيعان إلغاء الطلب المفتوح.
    public function cancel(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['parent', 'specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $learningSupportRequest = DB::table('learning_support_requests')->where('id', $id)->first();
        if (!$learningSupportRequest) {
            return response()->json(['error' => 'الطلب غير موجود'], 404);
        }
        if (in_array($learningSupportRequest->status, ['completed', 'cancelled'], true)) {
            return response()->json(['error' => 'الطلب منتهٍ بالفعل'], 409);
        }
        if ($user->role === 'parent') {
            if ((int) $learningSupportRequest->parent_id !== (int) $user->id || $learningSupportRequest->status !== 'pending') {
                return response()->json(['error' => 'لا يمكنك إلغاء هذا الطلب'], 403);
            }
        }

        DB::transaction(function () use ($id) {
            DB::table('learning_support_requests')->where('id', $id)->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('sessions')->where('learning_support_request_id', $id)->update([
                'status' => 'cancelled',
            ]);
        });

        if ($user->role !== 'parent') {
            Notify::toChildParents(
                $learningSupportRequest->child_id,
                'تم إلغاء طلب الدعم التعليمي',
                'تم إلغاء طلب جلسة الدعم التعليمي. يمكنك التواصل مع الدعم أو إرسال طلب جديد عند الحاجة.',
                'learning_support_request_cancelled'
            );
        }

        return response()->json(['ok' => true]);
    }
}
