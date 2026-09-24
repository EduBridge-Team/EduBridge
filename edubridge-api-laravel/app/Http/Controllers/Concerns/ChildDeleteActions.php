<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildDeleteActions
{
    public function destroy(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || $user->role !== 'admin') {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $deleted = DB::transaction(function () use ($id) {
                $child = DB::table('children')->where('id', $id)->first();
                if (!$child) {
                    return false;
                }

                DB::table('children')->where('id', $id)->delete();

                return true;
            });

            if (!$deleted) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            return response()->json(['message' => 'تم حذف الطفل بنجاح']);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'تعذّر حذف الطفل'], 500);
        }
    }
}
