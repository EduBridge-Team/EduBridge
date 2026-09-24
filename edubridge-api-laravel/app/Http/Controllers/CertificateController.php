<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\CertificateReadActions;
use App\Http\Controllers\Concerns\CertificateWriteActions;

class CertificateController extends Controller
{
    use CertificateReadActions;
    use CertificateWriteActions;
}
