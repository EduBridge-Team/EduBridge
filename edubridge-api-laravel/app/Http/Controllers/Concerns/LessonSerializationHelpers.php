<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LessonSerializationHelpers
{
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
}
