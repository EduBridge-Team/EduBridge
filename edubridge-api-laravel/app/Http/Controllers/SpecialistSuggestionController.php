<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\SpecialistSuggestionHelpers;
use App\Http\Controllers\Concerns\SpecialistSuggestionReadActions;
use App\Http\Controllers\Concerns\SpecialistSuggestionWriteActions;

class SpecialistSuggestionController extends Controller
{
    use SpecialistSuggestionHelpers;
    use SpecialistSuggestionReadActions;
    use SpecialistSuggestionWriteActions;

    private const SPECIALTIES = ['learning_support', 'educational', 'communication_support', 'learning_behavior'];
    private const STATUSES = ['pending', 'accepted', 'rejected'];
}
