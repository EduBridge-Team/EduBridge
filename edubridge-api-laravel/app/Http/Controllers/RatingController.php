<?php

namespace App\Http\Controllers;

// تقييمات المادة التعليمية (البطاقة 8)
// تقييم بالنجوم (1..5) مع تعليق اختياري، متوسط لكل درس، ومنع التقييم المكرر.
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RatingController extends Controller
{
    // تقييمات درس + المتوسط + تقييم المستخدم الحالي إن وُجد
    // GET /api/lessons/:id/ratings
    public function index(Request $request, $lessonId)
    {
        $me = $request->attributes->get('jwt_user');

        try {
            if (!DB::table('lessons')->where('id', $lessonId)->exists()) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }

            $ratings = DB::table('lesson_ratings as r')
                ->leftJoin('users as u', 'u.id', '=', 'r.user_id')
                ->where('r.lesson_id', $lessonId)
                ->select('r.id', 'r.stars', 'r.comment', 'r.created_at', 'u.name as user_name')
                ->orderByDesc('r.created_at')
                ->get();

            $agg = DB::table('lesson_ratings')
                ->where('lesson_id', $lessonId)
                ->selectRaw('COUNT(*) as count, COALESCE(AVG(stars), 0) as average')
                ->first();

            $mine = DB::table('lesson_ratings')
                ->where('lesson_id', $lessonId)
                ->where('user_id', $me->id)
                ->first();

            return response()->json([
                'ratings' => $ratings,
                'average' => round((float) $agg->average, 1),
                'count' => (int) $agg->count,
                'my_rating' => $mine,
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إضافة/تحديث تقييم المستخدم لدرس (upsert — يمنع التكرار)
    // POST /api/lessons/:id/ratings   body: { stars, comment? }
    public function store(Request $request, $lessonId)
    {
        $me = $request->attributes->get('jwt_user');

        $stars = (int) $request->input('stars');
        if ($stars < 1 || $stars > 5) {
            return response()->json(['error' => 'التقييم يجب أن يكون بين 1 و 5 نجوم'], 400);
        }

        // تعليق اختياري — نمنع التعليقات المسيئة الطويلة/الفارغة الغريبة بحد بسيط
        $comment = $request->input('comment');
        if (is_string($comment)) {
            $comment = trim($comment);
            if ($comment === '') {
                $comment = null;
            } elseif (mb_strlen($comment) > 1000) {
                return response()->json(['error' => 'التعليق طويل جداً'], 422);
            }
        } else {
            $comment = null;
        }

        try {
            if (!DB::table('lessons')->where('id', $lessonId)->exists()) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }

            $existing = DB::table('lesson_ratings')
                ->where('lesson_id', $lessonId)
                ->where('user_id', $me->id)
                ->first();

            if ($existing) {
                DB::table('lesson_ratings')->where('id', $existing->id)->update([
                    'stars' => $stars,
                    'comment' => $comment,
                ]);
                $id = $existing->id;
            } else {
                $id = DB::table('lesson_ratings')->insertGetId([
                    'lesson_id' => $lessonId,
                    'user_id' => $me->id,
                    'stars' => $stars,
                    'comment' => $comment,
                ]);
            }

            return response()->json(['rating' => DB::table('lesson_ratings')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // حذف تقييم (صاحبه أو الأدمن)
    // DELETE /api/ratings/:id
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
