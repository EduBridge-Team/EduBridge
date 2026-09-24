<?php

use Illuminate\Support\Facades\Route;

// إعدادات التكييف الخاصة بكل طفل
Route::get('/children/{childId}/accessibility-profile', [\App\Http\Controllers\ChildAccessibilityProfileController::class, 'show'])
    ->middleware('child.access');
Route::put('/children/{childId}/accessibility-profile', [\App\Http\Controllers\ChildAccessibilityProfileController::class, 'update'])
    ->middleware('child.access');

// التقييمات
Route::get('/evaluations/child/{childId}', [\App\Http\Controllers\EvaluationController::class, 'byChild'])
    ->middleware('child.access');
Route::post('/evaluations/child/{childId}', [\App\Http\Controllers\EvaluationController::class, 'store'])
    ->middleware(['role:teacher,specialist,admin', 'child.access']);

// أنواع الإعاقة
Route::get('/disability-types', [\App\Http\Controllers\DisabilityTypeController::class, 'index']);

// الدروس
Route::post('/lessons', [\App\Http\Controllers\LessonController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::match(['put', 'post'], '/lessons/{id}', [\App\Http\Controllers\LessonController::class, 'update'])
    ->middleware('role:teacher,specialist,admin');
Route::delete('/lessons/{id}', [\App\Http\Controllers\LessonController::class, 'destroy'])
    ->middleware('role:teacher,specialist,admin');
Route::get('/lessons', [\App\Http\Controllers\LessonController::class, 'index']);
Route::get('/lessons/search', [\App\Http\Controllers\LessonController::class, 'search']);
Route::get('/lessons/{id}', [\App\Http\Controllers\LessonController::class, 'show']);

// تقييمات المادة التعليمية
Route::get('/lessons/{id}/ratings', [\App\Http\Controllers\RatingController::class, 'index']);
Route::post('/lessons/{id}/ratings', [\App\Http\Controllers\RatingController::class, 'store']);
Route::delete('/ratings/{id}', [\App\Http\Controllers\RatingController::class, 'destroy']);

// وسائط الدروس
Route::get('/lessons/{id}/media', [\App\Http\Controllers\MediaController::class, 'index']);
Route::post('/lessons/{id}/media', [\App\Http\Controllers\MediaController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::delete('/media/{id}', [\App\Http\Controllers\MediaController::class, 'destroy'])
    ->middleware('role:teacher,specialist,admin');

// التقدّم
Route::post('/progress', [\App\Http\Controllers\ProgressController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::get('/progress/child/{childId}', [\App\Http\Controllers\ProgressController::class, 'byChild'])
    ->middleware('child.access');
Route::get('/progress/child/{childId}/summary', [\App\Http\Controllers\ProgressController::class, 'summary'])
    ->middleware('child.access');
