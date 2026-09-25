<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LearningSupportMeetingCompleteAction
{
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
}
