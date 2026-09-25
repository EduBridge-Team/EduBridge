<?php

use Illuminate\Support\Facades\Route;

// إحصائيات لوحة التحكم
Route::get('/dashboard/stats', [\App\Http\Controllers\DashboardController::class, 'stats']);

// الملف الشخصي والإعدادات
Route::get('/me', [\App\Http\Controllers\AccountController::class, 'me']);
Route::put('/me/password', [\App\Http\Controllers\AccountController::class, 'changePassword'])
    ->middleware('throttle:10,1');
Route::post('/me/avatar', [\App\Http\Controllers\AccountController::class, 'uploadAvatar']);
Route::delete('/me/avatar', [\App\Http\Controllers\AccountController::class, 'removeAvatar']);
Route::delete('/me', [\App\Http\Controllers\AccountController::class, 'destroy']);
Route::put('/me/specialty', [\App\Http\Controllers\SpecialistSuggestionController::class, 'updateSpecialty'])
    ->middleware('role:specialist');

Route::get('/settings', [\App\Http\Controllers\UserSettingsController::class, 'show']);
Route::put('/settings', [\App\Http\Controllers\UserSettingsController::class, 'update']);

Route::post('/assistant/chat', [\App\Http\Controllers\AssistantController::class, 'chat'])
    ->middleware('throttle:20,1');

// المحادثات
Route::get('/conversation-users', [\App\Http\Controllers\ConversationController::class, 'users']);
Route::get('/conversations', [\App\Http\Controllers\ConversationController::class, 'index']);
Route::post('/conversations', [\App\Http\Controllers\ConversationController::class, 'store'])
    ->middleware('throttle:20,1');
Route::get('/conversations/{conversationId}/messages', [\App\Http\Controllers\ConversationController::class, 'messages']);
Route::post('/conversations/{conversationId}/messages', [\App\Http\Controllers\ConversationController::class, 'send'])
    ->middleware('throttle:60,1');
