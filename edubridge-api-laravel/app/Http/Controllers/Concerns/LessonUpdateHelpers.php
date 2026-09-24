<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LessonUpdateHelpers
{
    private function lessonUpdatePayload(
        Request $request,
        $lesson,
        string $title,
        string $targetType,
        array $targetChildIds
    ): array {
        $disabilityTypeId = $request->has('disability_type_id')
            ? $request->input('disability_type_id')
            : $lesson->disability_type_id;

        if ($disabilityTypeId === '' || $disabilityTypeId === null) {
            $disabilityTypeId = null;
        }

        return [
            'title' => $title,
            'content' => $request->input('content', $lesson->content),
            'disability_type_id' => $disabilityTypeId,
            'education_level' => $request->input('education_level', $lesson->education_level ?? null),
            'target_type' => $targetType,
            'target_child_ids' => empty($targetChildIds)
                ? null
                : json_encode(array_values($targetChildIds)),
            'audio_description' => $request->input(
                'audio_description',
                $lesson->audio_description ?? null
            ),
        ];
    }

    private function replaceUploadedLessonMedia(Request $request, int $lessonId): void
    {
        $images = $this->imageFiles($request);
        if (count($images) > 0) {
            $this->deleteMediaByType($lessonId, 'image');

            foreach ($images as $image) {
                $this->persistUploadedMedia($image, $lessonId, 'image');
            }
        }

        foreach (['video', 'audio', 'caption', 'sign_language'] as $type) {
            $file = $request->file($type);

            if ($file && $file->isValid()) {
                $this->deleteMediaByType($lessonId, $type);
                $this->persistUploadedMedia($file, $lessonId, $type);
            }
        }
    }

    private function persistLessonUpdate(
        Request $request,
        $lesson,
        array $payload
    ): void {
        DB::table('lessons')->where('id', $lesson->id)->update($payload);
        $this->replaceUploadedLessonMedia($request, (int) $lesson->id);
    }
}
