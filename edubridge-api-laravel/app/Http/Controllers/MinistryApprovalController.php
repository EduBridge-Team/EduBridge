<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\MinistryApprovalCreateActions;
use App\Http\Controllers\Concerns\MinistryApprovalHelpers;
use App\Http\Controllers\Concerns\MinistryApprovalReadActions;
use App\Http\Controllers\Concerns\MinistryApprovalReviewActions;

class MinistryApprovalController extends Controller
{
    use MinistryApprovalHelpers;
    use MinistryApprovalReadActions;
    use MinistryApprovalCreateActions;
    use MinistryApprovalReviewActions;
}
