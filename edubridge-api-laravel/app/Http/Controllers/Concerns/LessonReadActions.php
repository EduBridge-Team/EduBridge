<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use App\Support\ListPage;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

trait LessonReadActions
{
    public function index(Request $request)
    {
        $paging = ListPage::parameters($request);
        try {
            $query = DB::table('lessons as l')->select('l.*');
            if ($paging !== null) {
                // Compute ratings only for the returned rows, without grouping the entire catalogue.
                $query->selectSub(DB::table('lesson_ratings')->selectRaw('COALESCE(ROUND(AVG(stars), 1), 0)')->whereColumn('lesson_id', 'l.id'), 'rating_avg')
                    ->selectSub(DB::table('lesson_ratings')->selectRaw('COUNT(*)')->whereColumn('lesson_id', 'l.id'), 'rating_count');
            } else {
                $query->leftJoin('lesson_ratings as r', 'r.lesson_id', '=', 'l.id')
                    ->selectRaw('COALESCE(ROUND(AVG(r.stars), 1), 0) as rating_avg')
                    ->selectRaw('COUNT(r.id) as rating_count')->groupBy('l.id');
            }
            $query->orderByDesc('l.created_at');
            \App\Support\LessonVisibility::scope($query, $request->attributes->get('jwt_user'), 'l.');

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

            if ($paging !== null) $this->filterLessonPage($query, $paging);
            $query->orderByDesc('l.id');
            if ($paging !== null) {
                $page = $query->paginate($paging['per_page'], ['*'], 'page', $paging['page']);
                $rows = collect($page->items());
            } else {
                $rows = $query->get();
            }
            $lessons = $this->serializeLessons($request, $rows);
            return response()->json(['lessons' => $lessons]
                + ($paging !== null ? ['pagination' => ListPage::metadata($page)] : []));
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function search(Request $request)
    {
        if ($request->query->has('page') || $request->query->has('per_page')) {
            return $this->index($request);
        }
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
            \App\Support\LessonVisibility::scope($query, $request->attributes->get('jwt_user'));

            $user = $request->attributes->get('jwt_user');
            if (($user->role ?? null) === 'parent') {
                $query->where('target_type', '!=', 'parents');
            }

            $lessons = $this->serializeLessons($request, $query->get());
            return response()->json(['lessons' => $lessons]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر البحث في الدروس'], 500);
        }
    }

    private function filterLessonPage($query, array $paging): void
    {
        $q = trim((string) ($paging['q'] ?? ''));
        $category = trim((string) ($paging['category'] ?? ''));
        if ($q === '' && ($category === '' || $category === 'الكل')) return;
        // Some older deployments have category; the baseline schema does not.
        $expression = "'غير مصنّف'";
        if (Schema::hasColumn('lessons', 'category')) {
            $expression = "CASE LOWER(TRIM(COALESCE(l.category, '')))"
                ." WHEN 'reading' THEN 'القراءة' WHEN 'math' THEN 'الرياضيات' WHEN 'mathematics' THEN 'الرياضيات'"
                ." WHEN 'life_skills' THEN 'مهارات الحياة' WHEN 'communication' THEN 'التواصل' WHEN 'arts' THEN 'الفنون'"
                ." ELSE COALESCE(NULLIF(TRIM(l.category), ''), 'غير مصنّف') END";
        }
        if ($category !== '' && $category !== 'الكل') $query->whereRaw("($expression) = ?", [$category]);
        if ($q !== '') ListPage::search($query, $q, ['l.title', 'l.content', "($expression)"]);
    }

    public function show(Request $request, $id)
    {
        try {
            $lesson = DB::table('lessons')->find($id);
            if (!$lesson) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }
            if (!\App\Support\LessonVisibility::allowed($request->attributes->get('jwt_user'), (int) $id)) {
                return response()->json(['error' => 'غير مصرّح بعرض هذا الدرس'], 403);
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
