<?php

use Illuminate\Support\Facades\Route;

// الدعم الفني والشكاوى
Route::get('/support', [\App\Http\Controllers\SupportController::class, 'index']);
Route::post('/support', [\App\Http\Controllers\SupportController::class, 'store']);
Route::put('/support/{id}', [\App\Http\Controllers\SupportController::class, 'update'])
    ->middleware('role:admin');
Route::get('/support/tickets', [\App\Http\Controllers\SupportController::class, 'index'])
    ->middleware('role:admin');
Route::put('/support/tickets/{id}/resolve', [\App\Http\Controllers\SupportController::class, 'resolve'])
    ->middleware('role:admin');

// دراسة الحالة مع المختصين
Route::get('/consultations', [\App\Http\Controllers\ConsultationController::class, 'index'])
    ->middleware('role:parent,teacher,specialist,admin');
Route::post('/consultations', [\App\Http\Controllers\ConsultationController::class, 'store'])
    ->middleware('role:parent,teacher,admin');
Route::get('/consultations/{id}', [\App\Http\Controllers\ConsultationController::class, 'show'])
    ->middleware('role:parent,teacher,specialist,admin');
Route::put('/consultations/{id}', [\App\Http\Controllers\ConsultationController::class, 'update'])
    ->middleware('role:specialist,admin');
Route::post('/consultations/{id}/notes', [\App\Http\Controllers\ConsultationController::class, 'addNote'])
    ->middleware('role:specialist,admin');
