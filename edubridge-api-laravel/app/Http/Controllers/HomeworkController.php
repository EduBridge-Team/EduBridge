<?php

namespace App\Http\Controllers;

class HomeworkController extends Controller
{
    private const ALLOWED_EXTENSIONS = ['jpg','jpeg','png','webp','pdf','mp3','m4a','wav','mp4','mov'];
    private const MAX_BYTES = 10 * 1024 * 1024;

    use \App\Http\Controllers\Concerns\HomeworkControllerHelpers;
    use \App\Http\Controllers\Concerns\HomeworkReadActions;
    use \App\Http\Controllers\Concerns\HomeworkAssignmentActions;
    use \App\Http\Controllers\Concerns\HomeworkSubmissionActions;
}
