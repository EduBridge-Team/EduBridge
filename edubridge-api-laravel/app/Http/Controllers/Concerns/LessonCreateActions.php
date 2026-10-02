<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use InvalidArgumentException;

trait LessonCreateActions
{
    public function store(Request $request)
    {
        $title = trim((string) $request->input('title', ''));
        if ($title === '') {
            return response()->json(['error' => 'عنوان الدرس مطلوب'], 400);
        }

        $request->validate(['category' => ['nullable', 'string', 'max:100']]);

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
        $this->beginLessonMedia();
        DB::beginTransaction();

        try {
            $lessonId = DB::table('lessons')->insertGetId([
                'title' => $title,
                'content' => $request->input('content'),
            ...(Schema::hasColumn('lessons', 'category') ? ['category' => trim((string) $request->input('category')) ?: null] : []),
                'disability_type_id' => $request->input('disability_type_id'),
                'education_level' => $request->input('education_level'),
                'teacher_id' => $user->id,
                'target_type' => $targetType,
                'target_child_ids' => empty($targetChildIds)
                    ? null
                    : json_encode(array_values($targetChildIds)),
                'audio_description' => $request->input('audio_description'),
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
            $this->commitLessonMedia();

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

            $this->rollbackLessonMedia();

            report($e);

            return response()->json(['error' => 'تعذّر حفظ الدرس ووسائطه'], 500);
        }
    }
}
