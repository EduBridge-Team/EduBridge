<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AssistantChatAction;
use App\Http\Controllers\Concerns\AssistantControllerHelpers;

class AssistantController extends Controller
{
    use AssistantControllerHelpers;
    use AssistantChatAction;
}
