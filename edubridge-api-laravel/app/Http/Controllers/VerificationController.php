<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\VerificationChildReviewActions;
use App\Http\Controllers\Concerns\VerificationSelfActions;
use App\Http\Controllers\Concerns\VerificationUserReviewActions;

class VerificationController extends Controller
{
    use VerificationSelfActions;
    use VerificationUserReviewActions;
    use VerificationChildReviewActions;

    private const STATUSES = ['pending', 'verified', 'rejected'];
}
