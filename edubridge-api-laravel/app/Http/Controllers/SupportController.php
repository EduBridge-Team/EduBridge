<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\SupportReadActions;
use App\Http\Controllers\Concerns\SupportWriteActions;

class SupportController extends Controller
{
    use SupportReadActions;
    use SupportWriteActions;

    private const CATEGORIES = ['support', 'complaint'];
    private const STATUSES = ['open', 'in_progress', 'resolved', 'closed'];
}
