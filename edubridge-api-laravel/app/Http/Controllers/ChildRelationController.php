<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChildControllerHelpers;
use App\Http\Controllers\Concerns\ChildRelationParentActions;
use App\Http\Controllers\Concerns\ChildRelationTeacherActions;

class ChildRelationController extends Controller
{
    use ChildControllerHelpers;
    use ChildRelationParentActions;
    use ChildRelationTeacherActions;
}
