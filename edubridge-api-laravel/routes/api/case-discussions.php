<?php

use Illuminate\Support\Facades\Route;

// دراسات الحالة التعاونية
Route::get('/case-discussions', [\App\Http\Controllers\CaseDiscussionController::class, 'index'])
    ->middleware('role:teacher,specialist,admin');
Route::post('/case-discussions', [\App\Http\Controllers\CaseDiscussionController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::get('/case-discussions/{id}', [\App\Http\Controllers\CaseDiscussionController::class, 'show'])
    ->middleware('role:teacher,specialist,admin');
Route::post('/case-discussions/{id}/messages', [\App\Http\Controllers\CaseDiscussionController::class, 'addMessage'])
    ->middleware('role:teacher,specialist,admin');
Route::put('/case-discussions/{id}/resolve', [\App\Http\Controllers\CaseDiscussionController::class, 'resolve'])
    ->middleware('role:teacher,specialist,admin');
