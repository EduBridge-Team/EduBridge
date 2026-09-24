<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\UserReadActions;
use App\Http\Controllers\Concerns\UserWriteActions;

class UserController extends Controller
{
    use UserReadActions;
    use UserWriteActions;

    private const ROLES = ['parent', 'teacher', 'specialist', 'admin', 'ministry', 'institution'];
}
