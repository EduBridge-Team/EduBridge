<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChildControllerHelpers;
use App\Http\Controllers\Concerns\ChildCreateActions;
use App\Http\Controllers\Concerns\ChildDeleteActions;
use App\Http\Controllers\Concerns\ChildReadActions;
use App\Http\Controllers\Concerns\ChildUpdateActions;
use App\Http\Controllers\Concerns\ChildUpdateHelpers;

class ChildController extends Controller
{
    use ChildControllerHelpers;
    use ChildReadActions;
    use ChildCreateActions;
    use ChildUpdateHelpers;
    use ChildUpdateActions;
    use ChildDeleteActions;

    private const TEXT_FIELDS = [
        'disability_type',
        'disability_description',
        'special_needs',
        'preferred_learning_style',
        'notes',
    ];

    private const IDENTITY_FIELDS = [
        'child_national_id',
        'guardian_national_id',
        'guardian_id_document_url',
        'kinship_document_url',
    ];
}
