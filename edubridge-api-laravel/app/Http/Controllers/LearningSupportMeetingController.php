<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\LearningSupportMeetingCancelAction;
use App\Http\Controllers\Concerns\LearningSupportMeetingCompleteAction;
use App\Http\Controllers\Concerns\LearningSupportMeetingScheduleAction;
use App\Http\Controllers\Concerns\LearningSupportMeetingScheduleHelpers;
use App\Http\Controllers\Concerns\LearningSupportRequestHelpers;

class LearningSupportMeetingController extends Controller
{
    use LearningSupportRequestHelpers;
    use LearningSupportMeetingScheduleHelpers;
    use LearningSupportMeetingScheduleAction;
    use LearningSupportMeetingCompleteAction;
    use LearningSupportMeetingCancelAction;
}
