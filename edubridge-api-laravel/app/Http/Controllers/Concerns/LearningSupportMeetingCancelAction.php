<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LearningSupportMeetingCancelAction
{
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
            if ((int) $learningSupportRequest->parent_id !== (int) $user->id
                || $learningSupportRequest->status !== 'pending') {
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
