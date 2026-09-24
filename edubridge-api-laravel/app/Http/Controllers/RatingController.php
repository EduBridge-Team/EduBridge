<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\RatingReadActions;
use App\Http\Controllers\Concerns\RatingWriteActions;

class RatingController extends Controller
{
    use RatingReadActions;
    use RatingWriteActions;
}
