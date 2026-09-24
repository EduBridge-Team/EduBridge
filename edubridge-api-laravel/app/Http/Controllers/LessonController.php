<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\LessonControllerHelpers;
use App\Http\Controllers\Concerns\LessonCreateActions;
use App\Http\Controllers\Concerns\LessonDeleteActions;
use App\Http\Controllers\Concerns\LessonReadActions;
use App\Http\Controllers\Concerns\LessonUpdateActions;

class LessonController extends Controller
{
    use LessonAccessHelpers;
    use LessonMediaHelpers;
    use LessonSerializationHelpers;
    use LessonReadActions;
    use LessonCreateActions;
    use LessonUpdateActions;
    use LessonDeleteActions;

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
}
