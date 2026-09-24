<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\MinistryApprovalHelpers;
use App\Http\Controllers\Concerns\MinistryApprovalReadActions;
use App\Http\Controllers\Concerns\MinistryApprovalWriteActions;

class MinistryApprovalController extends Controller
{
    use MinistryApprovalHelpers;
    use MinistryApprovalReadActions;
    use MinistryApprovalWriteActions;
}
