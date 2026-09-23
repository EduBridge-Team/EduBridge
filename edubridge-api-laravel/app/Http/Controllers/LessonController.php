<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class LessonController extends Controller
{
    use \App\Http\Controllers\Concerns\LessonControllerHelpers;

    private const TARGET_TYPES = ['everyone', 'byDisability', 'specificChildren', 'parents'];

    private const MEDIA_RULES = [
        'image' => [
            'extensions' => ['jpg', 'jpeg', 'png', 'webp'],
            'max_bytes' => 10 * 1024 * 1024,
        ],
        'video' => [
            'extensions' => ['mp4', 'webm', 'mov', 'm4v'],
            'max_bytes' => 150 * 1024 * 1024,
        ],
        'audio' => [
            'extensions' => ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
            'max_bytes' => 50 * 1024 * 1024,
        ],
        'caption' => [
            'extensions' => ['vtt', 'srt'],
            'max_bytes' => 5 * 1024 * 1024,
        ],
        'sign_language' => [
            'extensions' => ['mp4', 'webm', 'mov', 'm4v'],
            'max_bytes' => 150 * 1024 * 1024,
        ],
    ];

    // إضافة درس (معلّم / أدمن) مع صور/فيديو/صوت/ترجمات/لغة إشارة
    // POST /api/lessons (multipart/form-data أو JSON)
    public function store(Request $request)
    {
        $title = trim((string) $request->input('title', ''));
        if ($title === '') {
            return response()->json(['error' => 'عنوان الدرس مطلوب'], 400);
        }

        $targetType = (string) $request->input('target_type', 'everyone');
        if (!in_array($targetType, self::TARGET_TYPES, true)) {
            return response()->json(['error' => 'نوع استهداف الدرس غير صالح'], 422);
        }

        $targetChildIds = $this->parseTargetChildIds($request->input('target_child_ids'));
        if ($targetType === 'specificChildren' && empty($targetChildIds)) {
            return response()->json(['error' => 'اختر طالباً واحداً على الأقل'], 422);
        }

        $user = $request->attributes->get('jwt_user');
        if ($targetType === 'specificChildren' && !$this->canTargetChildren($user, $targetChildIds)) {
            return response()->json(['error' => 'يمكنك استهداف الأطفال المرتبطين بك فقط'], 403);
        }

        try {
            $this->validateUploadedMedia($request);
        } catch (InvalidArgumentException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }

        $lessonId = null;

        DB::beginTransaction();
        try {
            $lessonId = DB::table('lessons')->insertGetId([
                'title' => $title,
                'content' => $request->input('content'),
                'disability_type_id' => $request->input('disability_type_id'),
                'education_level' => $request->input('education_level'),
                'teacher_id' => $user->id,
                'target_type' => $targetType,
                'target_child_ids' => empty($targetChildIds) ? null : json_encode(array_values($targetChildIds)),
                'audio_description' => $request->input('audio_description'),
                // curriculum_status يبقى pending حسب القيمة الافتراضية في القاعدة.
            ]);

            foreach ($this->imageFiles($request) as $image) {
                $this->persistUploadedMedia($image, $lessonId, 'image');
            }

            foreach (['video', 'audio', 'caption', 'sign_language'] as $type) {
                $file = $request->file($type);
                if ($file && $file->isValid()) {
                    $this->persistUploadedMedia($file, $lessonId, $type);
                }
            }

            DB::commit();

            Notify::toParentsByDisabilityType(
                $request->input('disability_type_id'),
                'درس جديد',
                'تمت إضافة درس جديد: ' . $title,
                'lesson_added'
            );

            $lesson = DB::table('lessons')->find($lessonId);
            return response()->json([
                'lesson' => $this->serializeLesson($request, $lesson),
            ], 201);
        } catch (\Throwable $e) {
            DB::rollBack();
            if ($lessonId !== null) {
                $urls = DB::table('media')->where('lesson_id', $lessonId)->pluck('url')->all();
                $this->removeLessonObjects($urls);
            }
            report($e);
            return response()->json(['error' => 'تعذّر حفظ الدرس ووسائطه'], 500);
        }
    }

    // عرض الدروس، مع فلترة اختيارية حسب نوع الإعاقة
    // GET /api/lessons?disability_type_id=
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

    // عرض درس واحد مع وسائطه
    // GET /api/lessons/:id
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

    // تعديل درس — المعلّم/المختص يمكنه تعديل دروسه فقط، والأدمن يمكنه تعديل أي درس
    // POST|PUT /api/lessons/:id
    public function update(Request $request, $id)
    {
        $lesson = DB::table('lessons')->find($id);
        if (!$lesson) {
            return response()->json(['error' => 'الدرس غير موجود'], 404);
        }

        $user = $request->attributes->get('jwt_user');
        if (!$this->canManageLesson($user, $lesson)) {
            return response()->json(['error' => 'لا يمكنك تعديل درس لم تقم بإنشائه'], 403);
        }

        $title = trim((string) $request->input('title', $lesson->title));
        if ($title === '') {
            return response()->json(['error' => 'عنوان الدرس مطلوب'], 400);
        }

        $targetType = (string) $request->input('target_type', $lesson->target_type ?? 'everyone');
        if (!in_array($targetType, self::TARGET_TYPES, true)) {
            return response()->json(['error' => 'نوع استهداف الدرس غير صالح'], 422);
        }

        $existingTargetIds = $lesson->target_child_ids ?? null;
        $targetChildIds = $request->has('target_child_ids')
            ? $this->parseTargetChildIds($request->input('target_child_ids'))
            : $this->parseTargetChildIds($existingTargetIds);

        if ($targetType === 'specificChildren' && empty($targetChildIds)) {
            return response()->json(['error' => 'اختر طالباً واحداً على الأقل'], 422);
        }
        if ($targetType === 'specificChildren' && !$this->canTargetChildren($user, $targetChildIds)) {
            return response()->json(['error' => 'يمكنك استهداف الأطفال المرتبطين بك فقط'], 403);
        }

        try {
            $this->validateUploadedMedia($request);
        } catch (InvalidArgumentException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }

        $disabilityTypeId = $request->has('disability_type_id')
            ? $request->input('disability_type_id')
            : $lesson->disability_type_id;
        if ($disabilityTypeId === '' || $disabilityTypeId === null) {
            $disabilityTypeId = null;
        }

        DB::beginTransaction();
        try {
            DB::table('lessons')->where('id', $lesson->id)->update([
                'title' => $title,
                'content' => $request->input('content', $lesson->content),
                'disability_type_id' => $disabilityTypeId,
                'education_level' => $request->input('education_level', $lesson->education_level ?? null),
                'target_type' => $targetType,
                'target_child_ids' => empty($targetChildIds) ? null : json_encode(array_values($targetChildIds)),
                'audio_description' => $request->input('audio_description', $lesson->audio_description ?? null),
            ]);

            if (count($this->imageFiles($request)) > 0) {
                $this->deleteMediaByType((int) $lesson->id, 'image');
                foreach ($this->imageFiles($request) as $image) {
                    $this->persistUploadedMedia($image, (int) $lesson->id, 'image');
                }
            }

            foreach (['video', 'audio', 'caption', 'sign_language'] as $type) {
                $file = $request->file($type);
                if ($file && $file->isValid()) {
                    $this->deleteMediaByType((int) $lesson->id, $type);
                    $this->persistUploadedMedia($file, (int) $lesson->id, $type);
                }
            }

            DB::commit();

            $updated = DB::table('lessons')->find($lesson->id);
            return response()->json([
                'lesson' => $this->serializeLesson($request, $updated),
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            report($e);
            return response()->json(['error' => 'تعذّر تعديل الدرس'], 500);
        }
    }

    // حذف درس — صاحبه أو الأدمن فقط
    // DELETE /api/lessons/:id
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
