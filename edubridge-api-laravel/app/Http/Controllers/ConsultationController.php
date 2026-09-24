<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ConsultationAccess;
use App\Http\Controllers\Concerns\ConsultationReadActions;
use App\Http\Controllers\Concerns\ConsultationWriteActions;

class ConsultationController extends Controller
{
    use ConsultationAccess;
    use ConsultationReadActions;
    use ConsultationWriteActions;
}
