<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\LegacyMobileHelpers;
use App\Http\Controllers\Concerns\LegacyMobileVerificationReadActions;
use App\Http\Controllers\Concerns\LegacyMobileVerificationReviewActions;

class LegacyMobileController extends Controller
{
    use LegacyMobileHelpers;
    use LegacyMobileVerificationReadActions;
    use LegacyMobileVerificationReviewActions;
}
