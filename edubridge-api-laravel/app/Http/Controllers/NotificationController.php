<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\NotificationReadActions;
use App\Http\Controllers\Concerns\NotificationWriteActions;

class NotificationController extends Controller
{
    use NotificationReadActions;
    use NotificationWriteActions;
}
