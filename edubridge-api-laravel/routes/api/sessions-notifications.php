<?php

use Illuminate\Support\Facades\Route;

// اجتماعات الدعم التعليمي — مع إبقاء المسارات القديمة للتوافق التقني
Route::get('/learning-support/meetings', [\App\Http\Controllers\SessionController::class, 'index'])
    ->middleware('role:parent,teacher,specialist,admin');
Route::post('/learning-support/meetings', [\App\Http\Controllers\SessionController::class, 'store'])
    ->middleware('role:specialist,admin');
Route::put('/learning-support/meetings/{id}/complete', [\App\Http\Controllers\SessionController::class, 'complete'])
    ->middleware('role:specialist,admin');

Route::get('/sessions', [\App\Http\Controllers\SessionController::class, 'index'])
    ->middleware('role:specialist,admin');
Route::post('/sessions', [\App\Http\Controllers\SessionController::class, 'store'])
    ->middleware('role:specialist,admin');
Route::get('/sessions/child/{childId}', [\App\Http\Controllers\SessionController::class, 'byChild'])
    ->middleware(['role:specialist,admin,teacher', 'child.access']);
Route::put('/sessions/{id}', [\App\Http\Controllers\SessionController::class, 'update'])
    ->middleware('role:specialist,admin');

// الإشعارات
Route::get('/notifications', [\App\Http\Controllers\NotificationController::class, 'index']);
Route::post('/notifications/send', [\App\Http\Controllers\NotificationController::class, 'send'])
    ->middleware('role:specialist,admin');
Route::get('/notifications/unread/count', [\App\Http\Controllers\NotificationController::class, 'unreadCount']);
Route::match(['put', 'post'], '/notifications/read-all', [\App\Http\Controllers\NotificationController::class, 'markAllRead']);
Route::put('/notifications/{id}/read', [\App\Http\Controllers\NotificationController::class, 'markRead']);
