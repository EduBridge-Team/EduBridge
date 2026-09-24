<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CareTeamTeacherActions
{
    public function addTeacher(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$this->canManage($user, (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $teacherId = (int) $request->input('teacher_id');
        if (!$teacherId || !DB::table('users')->where('id', $teacherId)->where('role', 'teacher')->exists()) {
            return response()->json(['error' => 'المعلّم غير موجود'], 404);
        }

        if (!DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }

        DB::table('child_teacher')->insertOrIgnore([
            'child_id' => $childId,
            'teacher_id' => $teacherId,
            'subject' => $request->input('subject'),
            'assigned_at' => now(),
            'created_at' => now(),
        ]);

        Notify::toUser(
            $teacherId,
            'تمت إضافتك لفريق دعم تعليمي',
            'تم تعيينك ضمن فريق دعم تعليمي طفل.',
            'care_team_assigned'
        );

        return response()->json(['teachers' => $this->teachers((int) $childId)], 201);
    }

    public function removeTeacher(Request $request, $childId, $teacherId)
    {
        if (!$this->canManage($request->attributes->get('jwt_user'), (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::table('child_teacher')
            ->where('child_id', $childId)
            ->where('teacher_id', $teacherId)
            ->delete();

        return response()->json(['ok' => true]);
    }
}
