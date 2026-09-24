<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\CaseDiscussionControllerHelpers;
use App\Http\Controllers\Concerns\CaseDiscussionReadActions;
use App\Http\Controllers\Concerns\CaseDiscussionWriteActions;

class CaseDiscussionController extends Controller
{
    use CaseDiscussionControllerHelpers;
    use CaseDiscussionReadActions;
    use CaseDiscussionWriteActions;

    private const MESSAGE_TYPES = ['text','observation','decision','question'];
}
