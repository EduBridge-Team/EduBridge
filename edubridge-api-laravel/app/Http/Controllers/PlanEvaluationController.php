<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\PlanEvaluationHelpers;
use App\Http\Controllers\Concerns\PlanEvaluationWriteActions;

class PlanEvaluationController extends Controller
{
    use PlanEvaluationHelpers;
    use PlanEvaluationWriteActions;
}
