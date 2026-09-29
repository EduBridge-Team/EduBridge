<?php

use Illuminate\Support\Facades\Route;

Route::get('/children/{childId}/emergency-alerts', [\App\Http\Controllers\EmergencyAlertController::class, 'index']);
Route::post('/children/{childId}/emergency-alerts', [\App\Http\Controllers\EmergencyAlertController::class, 'store'])
    ->middleware('throttle:10,1');
Route::put('/emergency-alerts/{id}/resolve', [\App\Http\Controllers\EmergencyAlertController::class, 'resolve']);

Route::get('/children/{childId}/engagement', [\App\Http\Controllers\EngagementController::class, 'summary']);
Route::post('/children/{childId}/rewards/stars', [\App\Http\Controllers\EngagementController::class, 'addStars'])
    ->middleware('throttle:60,1');
Route::post('/children/{childId}/game-attempts', [\App\Http\Controllers\EngagementController::class, 'storeAttempt'])
    ->middleware('throttle:120,1');
