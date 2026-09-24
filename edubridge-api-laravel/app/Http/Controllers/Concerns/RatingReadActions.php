<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait RatingReadActions
{
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
}
