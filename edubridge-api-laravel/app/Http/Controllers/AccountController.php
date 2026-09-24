<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AccountAvatarActions;
use App\Http\Controllers\Concerns\AccountControllerHelpers;
use App\Http\Controllers\Concerns\AccountProfileActions;

class AccountController extends Controller
{
    use AccountControllerHelpers;
    use AccountAvatarActions;
    use AccountProfileActions;

    private const MIME_EXTENSIONS = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];

    private const MAX_BYTES = 5 * 1024 * 1024;
}
