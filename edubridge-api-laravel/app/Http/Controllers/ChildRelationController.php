<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChildControllerHelpers;
use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChildRelationController extends Controller
{
    use ChildControllerHelpers;

    public function addParent(Request $request, $id)
    {
        $parentId = $request->input('parent_id');
        if (!$parentId) {
            return response()->json(['error' => 'parent_id مطلوب'], 400);
        }
    
        try {
            if (!DB::table('children')->where('id', $id)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }
            if (!DB::table('users')->where('id', $parentId)->where('role', 'parent')->exists()) {
                return response()->json(['error' => 'ولي الأمر غير موجود'], 404);
            }
    
            // إدراج مع تجاهل التكرار (ON CONFLICT DO NOTHING)
            DB::table('child_parent')->insertOrIgnore([
                'child_id' => $id,
                'parent_id' => $parentId,
            ]);
    
            $child = DB::table('children')->where('id', $id)->first();
            Notify::toUser(
                $parentId,
                'تمت إضافة طفل',
                'تمت إضافة الطفل ' . ($child->name ?? '') . ' إلى حسابك',
                'child_added'
            );
    
            return response()->json(['message' => 'تم الربط'], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
    
    // تعيين معلّم مسؤول عن الطفل (أدمن فقط)
    // POST /api/children/:id/assign-teacher   body: { teacher_id }
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
    
            // إشعار أولياء أمر الطفل بتعيين المعلّم
            $child = DB::table('children')->where('id', $id)->first();
            $teacher = DB::table('users')->where('id', $teacherId)->first();
            Notify::toChildParents(
                $id,
                'تم تعيين معلّم',
                'تم تعيين المعلّم ' . ($teacher->name ?? '') . ' للطفل ' . ($child->name ?? ''),
                'child_assigned'
            );
    
            return response()->json(['child' => $this->decodeChild(DB::table('children')->find($id))]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
    
    // الدروس المناسبة لطفل معيّن: عامة، حسب نوع الإعاقة، أو مخصّصة للطفل.
    // GET /api/children/:id/lessons
}
