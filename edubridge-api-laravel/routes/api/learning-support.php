<?php

use Illuminate\Support\Facades\Route;

// طلبات الدعم التعليمي
Route::post('/learning-support/requests', [\App\Http\Controllers\LearningSupportRequestController::class, 'store'])
    ->middleware(['role:parent', 'throttle:10,1']);
Route::post('/learning-support/recommendations', [\App\Http\Controllers\LearningSupportRequestController::class, 'recommendToParent'])
    ->middleware(['role:specialist,admin', 'throttle:20,1']);
Route::get('/learning-support/requests', [\App\Http\Controllers\LearningSupportRequestController::class, 'index'])
    ->middleware('role:parent,specialist,admin');
Route::get('/learning-support/requests/child/{childId}/pending', [\App\Http\Controllers\LearningSupportRequestController::class, 'pendingForChild'])
    ->middleware(['role:parent,specialist,admin', 'child.access']);
Route::put('/learning-support/requests/{id}/schedule', [\App\Http\Controllers\LearningSupportMeetingController::class, 'schedule'])
    ->middleware('role:specialist,admin');
Route::put('/learning-support/requests/{id}/complete', [\App\Http\Controllers\LearningSupportMeetingController::class, 'complete'])
    ->middleware('role:specialist,admin');
Route::put('/learning-support/requests/{id}/cancel', [\App\Http\Controllers\LearningSupportMeetingController::class, 'cancel'])
    ->middleware('role:parent,specialist,admin');

// اقتراحات متابعة المختصين
Route::post('/children/{childId}/specialist-suggestions', [\App\Http\Controllers\SpecialistSuggestionController::class, 'store'])
    ->middleware(['role:teacher,specialist,admin', 'child.access']);
Route::get('/specialist-suggestions', [\App\Http\Controllers\SpecialistSuggestionController::class, 'index'])
    ->middleware('role:specialist,admin');
Route::put('/specialist-suggestions/{id}/accept', [\App\Http\Controllers\SpecialistSuggestionController::class, 'accept'])
    ->middleware('role:specialist,admin');
Route::put('/specialist-suggestions/{id}/reject', [\App\Http\Controllers\SpecialistSuggestionController::class, 'reject'])
    ->middleware('role:specialist,admin');
