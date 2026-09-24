<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildRelationTeacherActions
{
    public function assignTeacher(Request $request, $id)
    {
        $teacherId = $request->input('teacher_id');
        if (!$teacherId) {
            return response()->json(['error' => 'teacher_id مطلوب'], 400);
        }

        try {
            if (!DB::table('children')->where('id', $id)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }
            if (!DB::table('users')->where('id', $teacherId)->where('role', 'teacher')->exists()) {
                return response()->json(['error' => 'المعلّم غير موجود'], 404);
            }

            DB::table('children')->where('id', $id)->update([
                'assigned_teacher_id' => $teacherId,
                'status' => 'assigned',
            ]);

            $child = DB::table('children')->where('id', $id)->first();
            $teacher = DB::table('users')->where('id', $teacherId)->first();

            Notify::toChildParents(
                $id,
                'تم تعيين معلّم',
                'تم تعيين المعلّم ' . ($teacher->name ?? '') . ' للطفل ' . ($child->name ?? ''),
                'child_assigned'
            );

            return response()->json([
                'child' => $this->decodeChild(DB::table('children')->find($id)),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
