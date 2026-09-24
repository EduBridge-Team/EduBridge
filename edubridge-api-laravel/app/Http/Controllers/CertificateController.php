<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\CertificateDeleteActions;
use App\Http\Controllers\Concerns\CertificateReadActions;
use App\Http\Controllers\Concerns\CertificateReviewActions;
use App\Http\Controllers\Concerns\CertificateUploadActions;

class CertificateController extends Controller
{
    use CertificateReadActions;
    use CertificateUploadActions;
    use CertificateReviewActions;
    use CertificateDeleteActions;
}
