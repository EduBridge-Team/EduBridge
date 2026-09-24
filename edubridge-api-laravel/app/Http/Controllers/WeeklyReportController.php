<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\WeeklyReportControllerHelpers;
use App\Http\Controllers\Concerns\WeeklyReportGeneralWriteActions;
use App\Http\Controllers\Concerns\WeeklyReportReadActions;
use App\Http\Controllers\Concerns\WeeklyReportSpecialistWriteActions;

class WeeklyReportController extends Controller
{
    use WeeklyReportControllerHelpers;
    use WeeklyReportReadActions;
    use WeeklyReportGeneralWriteActions;
    use WeeklyReportSpecialistWriteActions;
}
