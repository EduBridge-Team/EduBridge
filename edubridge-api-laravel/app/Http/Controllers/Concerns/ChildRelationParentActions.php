<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildRelationParentActions
{
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
}
