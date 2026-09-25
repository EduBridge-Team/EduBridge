<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait MinistryReviewActions
{
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
