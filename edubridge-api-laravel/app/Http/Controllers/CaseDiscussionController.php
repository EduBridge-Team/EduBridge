<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\CaseDiscussionControllerHelpers;
use App\Http\Controllers\Concerns\CaseDiscussionCreateActions;
use App\Http\Controllers\Concerns\CaseDiscussionLifecycleActions;
use App\Http\Controllers\Concerns\CaseDiscussionMessageActions;
use App\Http\Controllers\Concerns\CaseDiscussionReadActions;

class CaseDiscussionController extends Controller
{
    use CaseDiscussionControllerHelpers;
    use CaseDiscussionReadActions;
    use CaseDiscussionCreateActions;
    use CaseDiscussionMessageActions;
    use CaseDiscussionLifecycleActions;

    private const MESSAGE_TYPES = ['text','observation','decision','question'];
}
