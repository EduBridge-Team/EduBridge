<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

trait LessonUpdateActions
{
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

        $payload = $this->lessonUpdatePayload(
            $request,
            $lesson,
            $title,
            $targetType,
            $targetChildIds
        );

        DB::beginTransaction();

        try {
            $this->persistLessonUpdate($request, $lesson, $payload);
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
}
