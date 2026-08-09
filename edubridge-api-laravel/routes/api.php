<?php

// مسارات الـ API
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ChildController;
use App\Http\Controllers\LessonController;
use App\Http\Controllers\ProgressController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\DisabilityTypeController;

// المصادقة (بدون توكن)
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/google', [AuthController::class, 'google']);

// كل ما يلي يتطلب توكن صالح
Route::middleware('auth.jwt')->group(function () {
    // مثال على مسار محمي — يعيد حمولة التوكن
    Route::get('/me', [AuthController::class, 'me']);

    // إدارة المستخدمين — لوحة التحكم الإدارية (أدمن فقط)
    Route::get('/users', [UserController::class, 'index'])
        ->middleware('role:admin');
    Route::put('/users/{id}', [UserController::class, 'update'])
        ->middleware('role:admin');

    // الأطفال
    Route::post('/children', [ChildController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/children', [ChildController::class, 'index']);
    Route::get('/children/{id}', [ChildController::class, 'show']);
    Route::post('/children/{id}/parents', [ChildController::class, 'addParent'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/children/{id}/lessons', [ChildController::class, 'lessons']);

    // أنواع الإعاقة (قائمة مرجعية)
    Route::get('/disability-types', [DisabilityTypeController::class, 'index']);

    // الدروس
    Route::post('/lessons', [LessonController::class, 'store'])
        ->middleware('role:teacher,admin');
    Route::get('/lessons', [LessonController::class, 'index']);
    Route::get('/lessons/{id}', [LessonController::class, 'show']);

    // التقدّم (ولي الأمر يعرض فقط — لا يعدّل)
    Route::post('/progress', [ProgressController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/progress/child/{childId}', [ProgressController::class, 'byChild']);
    Route::get('/progress/child/{childId}/summary', [ProgressController::class, 'summary']);
});
