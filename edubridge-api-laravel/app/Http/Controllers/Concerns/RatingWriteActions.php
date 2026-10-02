<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait RatingWriteActions
{
    public function store(Request $request, $lessonId)
    {
        $me = $request->attributes->get('jwt_user');
        $validated = $request->validate([
            'stars' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);
        $stars = (int) $validated['stars'];
        $comment = trim($validated['comment'] ?? '') ?: null;
        if ($comment !== null && \App\Services\RatingCommentPolicy::isAbusive($comment)) {
            return response()->json(['error' => 'يرجى كتابة تعليق محترم وخالٍ من الإساءة.'], 422);
        }

        try {
            if (!DB::table('lessons')->where('id', $lessonId)->exists()) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }
            if (!\App\Support\LessonVisibility::allowed($me, (int) $lessonId)) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            // The unique (lesson_id, user_id) key also protects concurrent requests.
            DB::table('lesson_ratings')->upsert([
                [
                    'lesson_id' => $lessonId,
                    'user_id' => $me->id,
                    'stars' => $stars,
                    'comment' => $comment,
                ],
            ], ['lesson_id', 'user_id'], ['stars', 'comment']);
            $rating = DB::table('lesson_ratings')
                ->where('lesson_id', $lessonId)
                ->where('user_id', $me->id)
                ->first();

            return response()->json([
                'rating' => $rating,
            ], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');

        try {
            $rating = DB::table('lesson_ratings')->where('id', $id)->first();
            if (!$rating) {
                return response()->json(['error' => 'التقييم غير موجود'], 404);
            }
            if ($me->role !== 'admin' && (int) $rating->user_id !== (int) $me->id) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            DB::table('lesson_ratings')->where('id', $id)->delete();

            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
