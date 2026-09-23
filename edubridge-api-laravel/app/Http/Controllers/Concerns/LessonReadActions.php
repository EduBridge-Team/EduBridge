<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LessonReadActions
{
    public function index(Request $request)
    {
        try {
            $query = DB::table('lessons as l')
                ->leftJoin('lesson_ratings as r', 'r.lesson_id', '=', 'l.id')
                ->select('l.*')
                ->selectRaw('COALESCE(ROUND(AVG(r.stars)::numeric, 1), 0) as rating_avg')
                ->selectRaw('COUNT(r.id) as rating_count')
                ->groupBy('l.id')
                ->orderByDesc('l.created_at');

            if ($request->query('disability_type_id')) {
                $query->where('l.disability_type_id', $request->query('disability_type_id'));
            }
            if ($request->query('curriculum_status')) {
                $query->where('l.curriculum_status', $request->query('curriculum_status'));
            }
            if ($request->query('target_type')) {
                $targetType = (string) $request->query('target_type');
                if (!in_array($targetType, self::TARGET_TYPES, true)) {
                    return response()->json(['error' => 'نوع استهداف الدرس غير صالح'], 422);
                }
                $query->where('l.target_type', $targetType);
            } else {
                $user = $request->attributes->get('jwt_user');
                if (($user->role ?? null) === 'parent') {
                    $query->where('l.target_type', '!=', 'parents');
                }
            }

            $lessons = $query->get()->map(
                fn ($lesson) => $this->serializeLesson($request, $lesson)
            );

            return response()->json(['lessons' => $lessons]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function search(Request $request)
    {
        $q = trim((string) $request->query('q', ''));
        if ($q === '') {
            return response()->json(['lessons' => []]);
        }

        try {
            $query = DB::table('lessons')
                ->where(function ($sub) use ($q) {
                    $sub->where('title', 'ILIKE', '%' . $q . '%')
                        ->orWhere('content', 'ILIKE', '%' . $q . '%');
                })
                ->orderByDesc('created_at')
                ->limit(50);

            $user = $request->attributes->get('jwt_user');
            if (($user->role ?? null) === 'parent') {
                $query->where('target_type', '!=', 'parents');
            }

            $lessons = $query->get()->map(fn ($lesson) => $this->serializeLesson($request, $lesson));
            return response()->json(['lessons' => $lessons]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر البحث في الدروس'], 500);
        }
    }

    public function show(Request $request, $id)
    {
        try {
            $lesson = DB::table('lessons')->find($id);
            if (!$lesson) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }

            $serialized = $this->serializeLesson($request, $lesson);
            return response()->json([
                'lesson' => $serialized,
                'media' => $serialized['media'],
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
