<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LessonDeleteActions
{
    public function destroy(Request $request, $id)
    {
        $lesson = DB::table('lessons')->find($id);
        if (!$lesson) {
            return response()->json(['error' => 'الدرس غير موجود'], 404);
        }

        $user = $request->attributes->get('jwt_user');
        if (!$this->canManageLesson($user, $lesson)) {
            return response()->json(['error' => 'لا يمكنك حذف درس لم تقم بإنشائه'], 403);
        }

        try {
            $mediaUrls = DB::table('media')
                ->where('lesson_id', $lesson->id)
                ->pluck('url')
                ->all();

            DB::table('lessons')->where('id', $lesson->id)->delete();
            $this->removeLessonObjects($mediaUrls);

            return response()->json(['ok' => true]);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر حذف الدرس'], 500);
        }
    }
}
