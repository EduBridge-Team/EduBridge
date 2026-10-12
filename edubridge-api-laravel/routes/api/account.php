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

// Noor learning memory: read, opt in/out, and delete are restricted to the assigned parent.
Route::get('/assistant/students/{child}/memory', [\App\Http\Controllers\NoorMemoryController::class, 'index'])
    ->middleware('throttle:30,1');
Route::patch('/assistant/students/{child}/memory/preferences', [\App\Http\Controllers\NoorMemoryController::class, 'preferences'])
    ->middleware('throttle:10,1');
Route::delete('/assistant/students/{child}/memory/{memory}', [\App\Http\Controllers\NoorMemoryController::class, 'destroy'])
    ->middleware('throttle:10,1');

Route::post('/assistant/chat', [\App\Http\Controllers\AssistantController::class, 'chat'])
    ->middleware('throttle:20,1');
Route::get('/assistant/students/{child}/context', [\App\Http\Controllers\NoorStudentContextController::class, 'show'])
    ->middleware('throttle:30,1');
Route::post('/assistant/students/{child}/draft-homework', [\App\Http\Controllers\NoorHomeworkDraftController::class, 'store'])
    ->middleware('throttle:10,1');
Route::post('/assistant/students/{child}/draft-progress', [\App\Http\Controllers\NoorProgressDraftController::class, 'store'])
    ->middleware('throttle:10,1');

// المحادثات
Route::get('/conversation-users', [\App\Http\Controllers\ConversationController::class, 'users']);
Route::get('/conversations', [\App\Http\Controllers\ConversationController::class, 'index']);
Route::post('/conversations', [\App\Http\Controllers\ConversationController::class, 'store'])
    ->middleware('throttle:20,1');
Route::get('/conversations/{conversationId}/messages', [\App\Http\Controllers\ConversationController::class, 'messages']);
Route::post('/conversations/{conversationId}/messages', [\App\Http\Controllers\ConversationController::class, 'send'])
    ->middleware('throttle:60,1');
