<?php

use Illuminate\Support\Facades\Route;

// إعدادات التكييف الخاصة بكل طفل — متزامنة بين الأجهزة
    Route::get('/children/{childId}/accessibility-profile', [\App\Http\Controllers\ChildAccessibilityProfileController::class, 'show'])->middleware('child.access');
    Route::put('/children/{childId}/accessibility-profile', [\App\Http\Controllers\ChildAccessibilityProfileController::class, 'update'])->middleware('child.access');

    // التقييمات
    Route::get('/evaluations/child/{childId}', [\App\Http\Controllers\EvaluationController::class, 'byChild'])->middleware('child.access');
    Route::post('/evaluations/child/{childId}', [\App\Http\Controllers\EvaluationController::class, 'store'])
        ->middleware(['role:teacher,specialist,admin', 'child.access']);

    // أنواع الإعاقة (قائمة مرجعية)
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

    // تقييمات المادة التعليمية (البطاقة 8)
    Route::get('/lessons/{id}/ratings', [\App\Http\Controllers\RatingController::class, 'index']);
    Route::post('/lessons/{id}/ratings', [\App\Http\Controllers\RatingController::class, 'store']);
    Route::delete('/ratings/{id}', [\App\Http\Controllers\RatingController::class, 'destroy']);

    // وسائط الدروس (صور / فيديو / صوت)
    Route::get('/lessons/{id}/media', [\App\Http\Controllers\MediaController::class, 'index']);
    Route::post('/lessons/{id}/media', [\App\Http\Controllers\MediaController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::delete('/media/{id}', [\App\Http\Controllers\MediaController::class, 'destroy'])
        ->middleware('role:teacher,specialist,admin');

    // التقدّم (ولي الأمر يعرض فقط — لا يعدّل)
    Route::post('/progress', [\App\Http\Controllers\ProgressController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/progress/child/{childId}', [\App\Http\Controllers\ProgressController::class, 'byChild'])->middleware('child.access');
    Route::get('/progress/child/{childId}/summary', [\App\Http\Controllers\ProgressController::class, 'summary'])->middleware('child.access');

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

    // الإشعارات — لكل مستخدم إشعاراته
    Route::get('/notifications', [\App\Http\Controllers\NotificationController::class, 'index']);
    Route::get('/notifications/unread/count', [\App\Http\Controllers\NotificationController::class, 'unreadCount']);
    // نقبل PUT و POST لتوافق الموقع والتطبيق معاً
    Route::match(['put', 'post'], '/notifications/read-all', [\App\Http\Controllers\NotificationController::class, 'markAllRead']);
    Route::put('/notifications/{id}/read', [\App\Http\Controllers\NotificationController::class, 'markRead']);
