<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ConversationAccess;
use App\Http\Controllers\Concerns\ConversationReadActions;
use App\Http\Controllers\Concerns\ConversationWriteActions;

class ConversationController extends Controller
{
    use ConversationAccess;
    use ConversationReadActions;
    use ConversationWriteActions;

    private const STAFF_ROLES = ['teacher', 'specialist', 'admin', 'ministry', 'institution'];
}
