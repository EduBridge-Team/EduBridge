<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

trait ChildLessonHelpers
{
    use LessonMediaBatchLoading;

    private function serializeChildLesson(Request $request, object $lesson, ?Collection $loadedMedia = null): array
    {
        $data = (array) $lesson;
        $rawTargets = $data['target_child_ids'] ?? null;

        if (is_string($rawTargets)) {
            $decoded = json_decode($rawTargets, true);
            $data['target_child_ids'] = is_array($decoded) ? $decoded : [];
        } elseif (!is_array($rawTargets)) {
            $data['target_child_ids'] = [];
        }

        $media = ($loadedMedia ?? DB::table('media')
            ->where('lesson_id', $lesson->id)
            ->select('id', 'lesson_id', 'type', 'url')
            ->orderBy('id')
            ->get())
            ->map(function ($item) use ($request) {
                $url = \App\Support\LessonFiles::forViewer($request, $item->url);

                return [
                    'id' => $item->id,
                    'lesson_id' => $item->lesson_id,
                    'type' => $item->type,
                    'url' => $url,
                ];
            })
            ->values()
            ->all();

        $first = function (string $type) use ($media) {
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
        $data['video_url'] = $first('video');
        $data['audio_url'] = $first('audio');
        $data['caption_url'] = $first('caption');
        $data['sign_language_url'] = $first('sign_language');

        return $data;
    }
}
