<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ConversationAccess;
use App\Http\Controllers\Concerns\ConversationCreateActions;
use App\Http\Controllers\Concerns\ConversationListActions;
use App\Http\Controllers\Concerns\ConversationMessageReadActions;
use App\Http\Controllers\Concerns\ConversationSendActions;
use App\Http\Controllers\Concerns\ConversationUserActions;

class ConversationController extends Controller
{
    use ConversationAccess;
    use ConversationUserActions;
    use ConversationListActions;
    use ConversationMessageReadActions;
    use ConversationCreateActions;
    use ConversationSendActions;

    private const STAFF_ROLES = ['teacher', 'specialist', 'admin', 'ministry', 'institution'];
}
