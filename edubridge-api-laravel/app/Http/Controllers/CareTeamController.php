<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\CareTeamControllerHelpers;
use App\Http\Controllers\Concerns\CareTeamMemberActions;
use App\Http\Controllers\Concerns\CareTeamReadActions;
use App\Http\Controllers\Concerns\CareTeamSpecialistActions;
use App\Http\Controllers\Concerns\CareTeamTeacherActions;

class CareTeamController extends Controller
{
    use CareTeamControllerHelpers;
    use CareTeamReadActions;
    use CareTeamMemberActions;
    use CareTeamTeacherActions;
    use CareTeamSpecialistActions;

    private const SPECIALTIES = ['educational','learning_support','communication_support','learning_behavior'];
}
