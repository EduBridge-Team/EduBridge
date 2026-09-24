<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\LearningSupportMeetingLifecycleActions;
use App\Http\Controllers\Concerns\LearningSupportMeetingScheduleAction;
use App\Http\Controllers\Concerns\LearningSupportMeetingScheduleHelpers;
use App\Http\Controllers\Concerns\LearningSupportRequestHelpers;

class LearningSupportMeetingController extends Controller
{
    use LearningSupportRequestHelpers;
    use LearningSupportMeetingScheduleHelpers;
    use LearningSupportMeetingScheduleAction;
    use LearningSupportMeetingLifecycleActions;
}
