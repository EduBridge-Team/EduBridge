<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\MediaControllerHelpers;
use App\Http\Controllers\Concerns\MediaReadActions;
use App\Http\Controllers\Concerns\MediaWriteActions;

class MediaController extends Controller
{
    use MediaControllerHelpers;
    use MediaReadActions;
    use MediaWriteActions;

    private const TYPES = ['image', 'video', 'audio', 'caption', 'sign_language'];

    private const RULES = [
        'image' => [['jpg', 'jpeg', 'png', 'webp'], 10 * 1024 * 1024],
        'video' => [['mp4', 'webm', 'mov', 'm4v'], 150 * 1024 * 1024],
        'audio' => [['mp3', 'm4a', 'aac', 'wav', 'ogg'], 50 * 1024 * 1024],
        'caption' => [['vtt', 'srt'], 5 * 1024 * 1024],
        'sign_language' => [['mp4', 'webm', 'mov', 'm4v'], 150 * 1024 * 1024],
    ];
}
