<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\MinistryReadActions;
use App\Http\Controllers\Concerns\MinistryReviewActions;
use App\Http\Controllers\Concerns\MinistryStatisticsActions;

class MinistryController extends Controller
{
    use MinistryReadActions;
    use MinistryStatisticsActions;
    use MinistryReviewActions;
}
