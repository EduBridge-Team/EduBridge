<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChildControllerHelpers;
use App\Http\Controllers\Concerns\ChildReadActions;
use App\Http\Controllers\Concerns\ChildWriteActions;

class ChildController extends Controller
{
    use ChildControllerHelpers;
    use ChildReadActions;
    use ChildWriteActions;

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
