<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChildAccessibilityProfileHelpers;
use App\Http\Controllers\Concerns\ChildAccessibilityProfileReadActions;
use App\Http\Controllers\Concerns\ChildAccessibilityProfileWriteActions;

class ChildAccessibilityProfileController extends Controller
{
    use ChildAccessibilityProfileHelpers;
    use ChildAccessibilityProfileReadActions;
    use ChildAccessibilityProfileWriteActions;
}
