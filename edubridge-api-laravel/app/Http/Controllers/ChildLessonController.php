<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChildLessonHelpers;
use App\Http\Controllers\Concerns\ChildLessonReadActions;

class ChildLessonController extends Controller
{
    use ChildLessonHelpers;
    use ChildLessonReadActions;
}
