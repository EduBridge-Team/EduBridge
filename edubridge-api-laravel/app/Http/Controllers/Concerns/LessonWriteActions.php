<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

trait LessonWriteActions
{
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
