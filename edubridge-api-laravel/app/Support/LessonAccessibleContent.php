<?php

namespace App\Support;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

final class LessonAccessibleContent
{
    public static function validate(Request $request): void
    {
        $raw = $request->input('image_descriptions');
        if (is_string($raw)) {
            $decoded = json_decode($raw, true);
            if (!is_array($decoded) || !array_is_list($decoded)) {
                throw ValidationException::withMessages(['image_descriptions' => 'أوصاف الصور يجب أن تكون قائمة']);
            }
            $request->merge(['image_descriptions' => $decoded]);
        }
        $request->validate([
            'image_descriptions' => ['sometimes', 'array', 'max:100'],
            'image_descriptions.*' => ['nullable', 'string', 'max:1000'],
            'real_life_example' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ]);
        if ($request->has('image_descriptions') && !array_is_list($request->input('image_descriptions'))) {
            throw ValidationException::withMessages(['image_descriptions' => 'أوصاف الصور يجب أن تكون قائمة مرتبة']);
        }
    }

    public static function payload(Request $request, int $imageCount, bool $replaceImages = false): array
    {
        $payload = [];
        if ($request->has('image_descriptions') || $replaceImages) {
            $descriptions = $request->input('image_descriptions', []);
            if (count($descriptions) > $imageCount) {
                throw ValidationException::withMessages(['image_descriptions' => 'عدد الأوصاف يتجاوز عدد الصور']);
            }
            if (Schema::hasColumn('lessons', 'image_descriptions')) {
                $payload['image_descriptions'] = json_encode(self::descriptions($descriptions, $imageCount), JSON_UNESCAPED_UNICODE);
            }
        }
        if ($request->has('real_life_example') && Schema::hasColumn('lessons', 'real_life_example')) {
            $payload['real_life_example'] = trim((string) $request->input('real_life_example')) ?: null;
        }
        return $payload;
    }

    public static function descriptions(mixed $raw, int $imageCount): array
    {
        if (is_string($raw)) $raw = json_decode($raw, true);
        $raw = is_array($raw) && array_is_list($raw) ? $raw : [];
        $result = [];
        for ($i = 0; $i < $imageCount; $i++) {
            $value = $raw[$i] ?? null;
            $result[] = is_string($value) ? (trim($value) ?: null) : null;
        }
        return $result;
    }
}
