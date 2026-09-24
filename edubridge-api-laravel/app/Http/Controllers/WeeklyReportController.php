<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\WeeklyReportAccessHelpers;
use App\Http\Controllers\Concerns\WeeklyReportControllerHelpers;
use App\Http\Controllers\Concerns\WeeklyReportEnrichmentHelpers;
use App\Http\Controllers\Concerns\WeeklyReportGeneralWriteActions;
use App\Http\Controllers\Concerns\WeeklyReportReadActions;
use App\Http\Controllers\Concerns\WeeklyReportSpecialistHelpers;
use App\Http\Controllers\Concerns\WeeklyReportSpecialistWriteActions;

class WeeklyReportController extends Controller
{
    use WeeklyReportAccessHelpers;
    use WeeklyReportControllerHelpers;
    use WeeklyReportEnrichmentHelpers;
    use WeeklyReportReadActions;
    use WeeklyReportGeneralWriteActions;
    use WeeklyReportSpecialistHelpers;
    use WeeklyReportSpecialistWriteActions;
}
