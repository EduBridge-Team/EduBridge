<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ConsultationAccess;
use App\Http\Controllers\Concerns\ConsultationCreateActions;
use App\Http\Controllers\Concerns\ConsultationNoteActions;
use App\Http\Controllers\Concerns\ConsultationReadActions;
use App\Http\Controllers\Concerns\ConsultationUpdateActions;

class ConsultationController extends Controller
{
    use ConsultationAccess;
    use ConsultationReadActions;
    use ConsultationCreateActions;
    use ConsultationUpdateActions;
    use ConsultationNoteActions;
}
