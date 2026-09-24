<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\CareTeamControllerHelpers;
use App\Http\Controllers\Concerns\CareTeamReadActions;
use App\Http\Controllers\Concerns\CareTeamWriteActions;

class CareTeamController extends Controller
{
    use CareTeamControllerHelpers;
    use CareTeamReadActions;
    use CareTeamWriteActions;

    private const SPECIALTIES = ['educational','learning_support','communication_support','learning_behavior'];
}
