<?php

namespace App\Http\Controllers;

// مسارات الدروس
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;

class LessonController extends Controller
{
    // إضافة درس (معلّم / أدمن)
    // POST /api/lessons
    public function store(Request $request)
    {
        if (!$request->input('title')) {
            return response()->json(['error' => 'عنوان الدرس مطلوب'], 400);
        }

        $user = $request->attributes->get('jwt_user');

        try {
            $id = DB::table('lessons')->insertGetId([
                'title' => $request->input('title'),
                'content' => $request->input('content'),
                'disability_type_id' => $request->input('disability_type_id'),
                'education_level' => $request->input('education_level'),
                'teacher_id' => $user->id,
                // يبقى 'pending' (افتراضي القاعدة) حتى تعتمده الوزارة — البطاقة 3
            ]);

            // إشعار أولياء أمر الأطفال المطابقين لنوع إعاقة الدرس الجديد
            Notify::toParentsByDisabilityType(
                $request->input('disability_type_id'),
                'درس جديد',
                'تمت إضافة درس جديد: ' . $request->input('title'),
                'lesson_added'
            );

            return response()->json(['lesson' => DB::table('lessons')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // عرض الدروس، مع فلترة اختيارية حسب نوع الإعاقة
    // GET /api/lessons?disability_type_id=
    public function index(Request $request)
    {
        try {
            // نُرفق متوسط التقييم وعددها لكل درس — البطاقة 8
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
            // فلترة اختيارية حسب حالة اعتماد المنهج — البطاقة 3
            if ($request->query('curriculum_status')) {
                $query->where('l.curriculum_status', $request->query('curriculum_status'));
            }

            return response()->json(['lessons' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // عرض درس واحد مع وسائطه
    // GET /api/lessons/:id
    public function show($id)
    {
        try {
            $lesson = DB::table('lessons')->find($id);
            if (!$lesson) {
                return response()->json(['error' => 'الدرس غير موجود'], 404);
            }

            $media = DB::table('media')
                ->where('lesson_id', $id)
                ->select('id', 'type', 'url')
                ->get();

            return response()->json(['lesson' => $lesson, 'media' => $media]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
