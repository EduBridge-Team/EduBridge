<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\LearningSupportRequestHelpers;
use App\Http\Controllers\Concerns\LearningSupportRequestReadActions;
use App\Http\Controllers\Concerns\LearningSupportRequestWriteActions;

class LearningSupportRequestController extends Controller
{
    use LearningSupportRequestHelpers;
    use LearningSupportRequestReadActions;
    use LearningSupportRequestWriteActions;
}
