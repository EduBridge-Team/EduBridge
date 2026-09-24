<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\UploadControllerHelpers;
use App\Http\Controllers\Concerns\UploadReadActions;
use App\Http\Controllers\Concerns\UploadWriteActions;

class UploadController extends Controller
{
    use UploadControllerHelpers;
    use UploadReadActions;
    use UploadWriteActions;

    private const ALLOWED = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];

    private const ALLOWED_MIME = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf',
    ];

    private const MAX_BYTES = 5 * 1024 * 1024;
}
