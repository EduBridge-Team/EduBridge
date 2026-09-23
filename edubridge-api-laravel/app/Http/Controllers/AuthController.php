<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AuthControllerHelpers;
use App\Http\Controllers\Concerns\AuthCredentialActions;
use App\Http\Controllers\Concerns\AuthGoogleActions;

class AuthController extends Controller
{
    use AuthControllerHelpers;
    use AuthCredentialActions;
    use AuthGoogleActions;
}
