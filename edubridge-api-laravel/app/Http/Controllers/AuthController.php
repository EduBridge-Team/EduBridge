<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AuthControllerHelpers;
use App\Http\Controllers\Concerns\AuthGoogleActions;
use App\Http\Controllers\Concerns\AuthLoginActions;
use App\Http\Controllers\Concerns\AuthRegisterActions;
use App\Http\Controllers\Concerns\AuthRegisterHelpers;

class AuthController extends Controller
{
    use AuthControllerHelpers;
    use AuthRegisterHelpers;
    use AuthRegisterActions;
    use AuthLoginActions;
    use AuthGoogleActions;
}
