<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\EvaluationControllerHelpers;
use App\Http\Controllers\Concerns\EvaluationReadActions;
use App\Http\Controllers\Concerns\EvaluationWriteActions;

class EvaluationController extends Controller
{
    use EvaluationControllerHelpers;
    use EvaluationReadActions;
    use EvaluationWriteActions;
}
