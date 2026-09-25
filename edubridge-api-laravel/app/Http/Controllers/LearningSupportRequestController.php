<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\LearningSupportRecommendationActions;
use App\Http\Controllers\Concerns\LearningSupportRequestCreateActions;
use App\Http\Controllers\Concerns\LearningSupportRequestHelpers;
use App\Http\Controllers\Concerns\LearningSupportRequestReadActions;

class LearningSupportRequestController extends Controller
{
    use LearningSupportRequestHelpers;
    use LearningSupportRequestReadActions;
    use LearningSupportRequestCreateActions;
    use LearningSupportRecommendationActions;
}
