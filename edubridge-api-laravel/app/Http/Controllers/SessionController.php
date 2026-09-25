<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\SessionCompleteActions;
use App\Http\Controllers\Concerns\SessionControllerHelpers;
use App\Http\Controllers\Concerns\SessionCreateActions;
use App\Http\Controllers\Concerns\SessionReadActions;
use App\Http\Controllers\Concerns\SessionUpdateActions;

class SessionController extends Controller
{
    use SessionControllerHelpers;
    use SessionReadActions;
    use SessionCreateActions;
    use SessionCompleteActions;
    use SessionUpdateActions;

    private const DB_STATUSES = ['scheduled', 'done', 'cancelled'];
    private const TYPES = ['learningPlanning', 'followUp', 'parentReview', 'teamReview', 'groupSupport'];
}
