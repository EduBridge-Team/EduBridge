<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LearningSupportMeetingScheduleAction
{
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
            DB::transaction(function () use (
                $id,
                $learningSupportRequest,
                $assignedSpecialistId,
                $scheduledAt,
                $meetingLink,
                $notes
            ) {
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

            $childName = (string) (DB::table('children')
                ->where('id', $learningSupportRequest->child_id)
                ->value('name') ?? '');

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
}
