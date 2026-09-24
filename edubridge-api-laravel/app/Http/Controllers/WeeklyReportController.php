<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\WeeklyReportControllerHelpers;
use App\Http\Controllers\Concerns\WeeklyReportReadActions;
use App\Http\Controllers\Concerns\WeeklyReportWriteActions;

class WeeklyReportController extends Controller
{
    use WeeklyReportControllerHelpers;
    use WeeklyReportReadActions;
    use WeeklyReportWriteActions;
}
