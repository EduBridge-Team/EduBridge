<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\LegacyMobileHelpers;
use App\Http\Controllers\Concerns\LegacyMobileVerificationActions;

class LegacyMobileController extends Controller
{
    use LegacyMobileHelpers;
    use LegacyMobileVerificationActions;
}
