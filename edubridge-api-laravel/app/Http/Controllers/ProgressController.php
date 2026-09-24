<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ProgressControllerHelpers;
use App\Http\Controllers\Concerns\ProgressReadActions;
use App\Http\Controllers\Concerns\ProgressWriteActions;

class ProgressController extends Controller
{
    use ProgressControllerHelpers;
    use ProgressReadActions;
    use ProgressWriteActions;
}
