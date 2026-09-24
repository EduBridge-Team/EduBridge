<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\SessionControllerHelpers;
use App\Http\Controllers\Concerns\SessionReadActions;
use App\Http\Controllers\Concerns\SessionWriteActions;

class SessionController extends Controller
{
    use SessionControllerHelpers;
    use SessionReadActions;
    use SessionWriteActions;

    private const DB_STATUSES = ['scheduled', 'done', 'cancelled'];
    private const TYPES = ['learningPlanning', 'followUp', 'parentReview', 'teamReview', 'groupSupport'];
}
