<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\SpecialistSuggestionCreateActions;
use App\Http\Controllers\Concerns\SpecialistSuggestionHelpers;
use App\Http\Controllers\Concerns\SpecialistSuggestionReadActions;
use App\Http\Controllers\Concerns\SpecialistSuggestionResponseActions;
use App\Http\Controllers\Concerns\SpecialistSuggestionSpecialtyActions;

class SpecialistSuggestionController extends Controller
{
    use SpecialistSuggestionHelpers;
    use SpecialistSuggestionReadActions;
    use SpecialistSuggestionSpecialtyActions;
    use SpecialistSuggestionCreateActions;
    use SpecialistSuggestionResponseActions;

    private const SPECIALTIES = ['learning_support', 'educational', 'communication_support', 'learning_behavior'];
    private const STATUSES = ['pending', 'accepted', 'rejected'];
}
