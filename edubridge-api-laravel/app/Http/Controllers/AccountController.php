<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AccountAvatarActions;
use App\Http\Controllers\Concerns\AccountControllerHelpers;
use App\Http\Controllers\Concerns\AccountDeleteActions;
use App\Http\Controllers\Concerns\AccountPasswordActions;
use App\Http\Controllers\Concerns\AccountProfileReadActions;

class AccountController extends Controller
{
    use AccountControllerHelpers;
    use AccountAvatarActions;
    use AccountProfileReadActions;
    use AccountPasswordActions;
    use AccountDeleteActions;

    private const MIME_EXTENSIONS = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];

    private const MAX_BYTES = 5 * 1024 * 1024;
}
