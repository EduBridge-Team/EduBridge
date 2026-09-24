<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// المصادقة (بدون توكن)
Route::post('/auth/register', [AuthController::class, 'register'])
    ->middleware('throttle:5,1');
Route::post('/auth/login', [AuthController::class, 'login'])
    ->middleware('throttle:10,1');
Route::post('/auth/google', [AuthController::class, 'google'])
    ->middleware('throttle:10,1');

// كل ما يلي يتطلب توكن صالح
Route::middleware('auth.jwt')->group(function () {
    require __DIR__ . '/api/account-admin.php';
    require __DIR__ . '/api/support-children.php';
    require __DIR__ . '/api/learning-content.php';
});
