<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class LessonController extends Controller
{
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

        try {
            $this->validateUploadedMedia($request);
        } catch (InvalidArgumentException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }

        $user = $request->attributes->get('jwt_user');
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
                $this->removeLessonUploadDirectory($lessonId);
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
            DB::table('lessons')->where('id', $lesson->id)->delete();
            $this->removeLessonUploadDirectory((int) $lesson->id);

            return response()->json(['ok' => true]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حذف الدرس'], 500);
        }
    }

    private function canManageLesson($user, $lesson): bool
    {
        if (!$user) {
            return false;
        }

        if (($user->role ?? null) === 'admin') {
            return true;
        }

        return (int) ($lesson->teacher_id ?? 0) === (int) ($user->id ?? 0);
    }

    private function deleteMediaByType(int $lessonId, string $type): void
    {
        $items = DB::table('media')
            ->where('lesson_id', $lessonId)
            ->where('type', $type)
            ->get(['id', 'url']);

        foreach ($items as $item) {
            $path = parse_url((string) $item->url, PHP_URL_PATH) ?: '';
            $key = ltrim($path, '/');
            if (str_starts_with($key, 'lessons/')) {
                try {
                    R2Storage::delete(R2Storage::mediaBucket(), $key);
                } catch (\Throwable $e) {
                    report($e);
                }
            }
        }

        DB::table('media')
            ->where('lesson_id', $lessonId)
            ->where('type', $type)
            ->delete();
    }

    private function imageFiles(Request $request): array
    {
        $images = $request->file('images', []);
        if (!is_array($images)) {
            $images = [$images];
        }

        $single = $request->file('image');
        if ($single) {
            $images[] = $single;
        }

        return array_values(array_filter($images, fn ($file) => $file && $file->isValid()));
    }

    private function parseTargetChildIds($raw): array
    {
        if ($raw === null || $raw === '') {
            return [];
        }

        if (is_string($raw)) {
            $decoded = json_decode($raw, true);
            $raw = is_array($decoded) ? $decoded : [];
        }

        if (!is_array($raw)) {
            return [];
        }

        return array_values(array_unique(array_filter(
            array_map('intval', $raw),
            fn ($id) => $id > 0
        )));
    }

    private function validateUploadedMedia(Request $request): void
    {
        foreach ($this->imageFiles($request) as $file) {
            $this->validateOneFile($file, 'image');
        }

        foreach (['video', 'audio', 'caption', 'sign_language'] as $type) {
            $file = $request->file($type);
            if ($file) {
                if (!$file->isValid()) {
                    throw new InvalidArgumentException('تعذّر قراءة ملف ' . $type);
                }
                $this->validateOneFile($file, $type);
            }
        }
    }

    private function validateOneFile($file, string $type): void
    {
        $rules = self::MEDIA_RULES[$type];
        $extension = strtolower((string) $file->getClientOriginalExtension());

        if (!in_array($extension, $rules['extensions'], true)) {
            throw new InvalidArgumentException(
                'صيغة ملف ' . $type . ' غير مدعومة. الصيغ المسموحة: ' .
                implode(', ', $rules['extensions'])
            );
        }

        if ((int) $file->getSize() > $rules['max_bytes']) {
            $maxMb = (int) ceil($rules['max_bytes'] / 1024 / 1024);
            throw new InvalidArgumentException("حجم ملف {$type} يتجاوز {$maxMb}MB");
        }
    }

    private function persistUploadedMedia($file, int $lessonId, string $type): void
    {
        $extension = strtolower((string) $file->getClientOriginalExtension());
        $filename = $type . '_' . bin2hex(random_bytes(10)) . '.' . $extension;
        $key = 'lessons/' . $lessonId . '/' . $filename;

        R2Storage::putUploadedFile(
            R2Storage::mediaBucket(),
            $key,
            $file,
            (string) $file->getMimeType()
        );

        DB::table('media')->insert([
            'lesson_id' => $lessonId,
            'type' => $type,
            'url' => R2Storage::mediaPublicUrl($key),
        ]);
    }

    private function serializeLesson(Request $request, $lesson): array
    {
        $data = (array) $lesson;

        if (array_key_exists('target_child_ids', $data)) {
            $raw = $data['target_child_ids'];
            if (is_string($raw)) {
                $decoded = json_decode($raw, true);
                $data['target_child_ids'] = is_array($decoded) ? $decoded : [];
            } elseif (!is_array($raw)) {
                $data['target_child_ids'] = [];
            }
        }

        $media = DB::table('media')
            ->where('lesson_id', $lesson->id)
            ->select('id', 'lesson_id', 'type', 'url')
            ->orderBy('id')
            ->get()
            ->map(function ($item) use ($request) {
                return [
                    'id' => $item->id,
                    'lesson_id' => $item->lesson_id,
                    'type' => $item->type,
                    'url' => $this->absoluteMediaUrl($request, $item->url),
                ];
            })
            ->values()
            ->all();

        $firstUrl = function (string $type) use ($media) {
            foreach ($media as $item) {
                if ($item['type'] === $type) {
                    return $item['url'];
                }
            }
            return null;
        };

        $images = array_values(array_map(
            fn ($item) => $item['url'],
            array_filter($media, fn ($item) => $item['type'] === 'image')
        ));

        $data['media'] = $media;
        $data['images'] = $images;
        $data['image_urls'] = $images;
        $data['video_url'] = $firstUrl('video');
        $data['audio_url'] = $firstUrl('audio');
        $data['caption_url'] = $firstUrl('caption');
        $data['sign_language_url'] = $firstUrl('sign_language');

        return $data;
    }

    private function absoluteMediaUrl(Request $request, ?string $url): ?string
    {
        if (!$url) {
            return null;
        }
        if (preg_match('/^https?:\/\//i', $url)) {
            return $url;
        }

        return rtrim($request->getSchemeAndHttpHost(), '/') . '/' . ltrim($url, '/');
    }

    private function removeLessonUploadDirectory(int $lessonId): void
    {
        $items = DB::table('media')->where('lesson_id', $lessonId)->get(['url']);
        foreach ($items as $item) {
            $path = parse_url((string) $item->url, PHP_URL_PATH) ?: '';
            $key = ltrim($path, '/');
            if (str_starts_with($key, 'lessons/')) {
                try {
                    R2Storage::delete(R2Storage::mediaBucket(), $key);
                } catch (\Throwable $e) {
                    report($e);
                }
            }
        }
    }
}
