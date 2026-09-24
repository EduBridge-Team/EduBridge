<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait MinistryApprovalReviewActions
{
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

        if (!$approval) {
            return response()->json(['error' => 'الطلب غير موجود'], 404);
        }

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
            : 'تم رفض الخطة التعليمية'
                . ($request->input('reason') ? ': ' . $request->input('reason') : '.');

        Notify::toUser($approval->submitted_by, $title, $message, 'ministry_approval');

        if ($approval->teacher_id) {
            Notify::toUser($approval->teacher_id, $title, $message, 'ministry_approval');
        }

        Notify::toChildParents(
            $approval->child_id,
            $title,
            $message,
            'ministry_approval'
        );

        $row = $this->query()->where('a.id', $id)->first();

        return response()->json([
            'approval' => $this->normalize($row),
        ]);
    }
}
