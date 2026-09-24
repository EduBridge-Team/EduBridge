<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\VerificationReviewActions;
use App\Http\Controllers\Concerns\VerificationSelfActions;

class VerificationController extends Controller
{
    use VerificationSelfActions;
    use VerificationReviewActions;

    private const STATUSES = ['pending', 'verified', 'rejected'];
}
