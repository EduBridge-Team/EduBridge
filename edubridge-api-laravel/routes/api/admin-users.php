<?php

use Illuminate\Support\Facades\Route;

// إدارة المستخدمين
Route::get('/users', [\App\Http\Controllers\UserController::class, 'index'])
    ->middleware('role:parent,teacher,specialist,admin,ministry,institution');
Route::put('/users/{id}', [\App\Http\Controllers\UserController::class, 'update'])
    ->middleware('role:admin');
Route::delete('/users/{id}', [\App\Http\Controllers\UserController::class, 'destroy'])
    ->middleware('role:admin');

// رفع الملفات الخاصة
Route::post('/uploads', [\App\Http\Controllers\UploadController::class, 'store'])
    ->middleware('throttle:20,1');
Route::get('/private-files/user/{userId}/{filename}', [\App\Http\Controllers\UploadController::class, 'show'])
    ->where('filename', '[A-Za-z0-9._-]+');
Route::get('/private-files/child/{childId}/{filename}', [\App\Http\Controllers\UploadController::class, 'showChild'])
    ->where('filename', '[A-Za-z0-9._-]+');

// توثيق الهوية
Route::post('/me/identity', [\App\Http\Controllers\VerificationController::class, 'submitMine']);
Route::get('/me/verification', [\App\Http\Controllers\VerificationController::class, 'myStatus']);
Route::get('/verifications/users', [\App\Http\Controllers\VerificationController::class, 'users'])
    ->middleware('role:admin');
Route::put('/verifications/users/{id}', [\App\Http\Controllers\VerificationController::class, 'reviewUser'])
    ->middleware('role:admin');
Route::get('/verifications/children', [\App\Http\Controllers\VerificationController::class, 'children'])
    ->middleware('role:admin');
Route::put('/verifications/children/{id}', [\App\Http\Controllers\VerificationController::class, 'reviewChild'])
    ->middleware('role:admin');

// توافق التطبيق القديم مع شاشة الأدمن
Route::get('/admin/verifications', [\App\Http\Controllers\LegacyMobileController::class, 'adminVerifications'])
    ->middleware('role:admin');
Route::post('/admin/verifications/{id}/approve', [\App\Http\Controllers\LegacyMobileController::class, 'approveVerification'])
    ->middleware('role:admin');
Route::post('/admin/verifications/{id}/reject', [\App\Http\Controllers\LegacyMobileController::class, 'rejectVerification'])
    ->middleware('role:admin');
Route::get('/admin/search', [\App\Http\Controllers\SearchController::class, 'byNationalId'])
    ->middleware('role:admin');

// الشهادات والبحث
Route::get('/certificates', [\App\Http\Controllers\CertificateController::class, 'index']);
Route::post('/certificates', [\App\Http\Controllers\CertificateController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::put('/certificates/{id}', [\App\Http\Controllers\CertificateController::class, 'review'])
    ->middleware('role:admin');
Route::delete('/certificates/{id}', [\App\Http\Controllers\CertificateController::class, 'destroy']);

Route::get('/search/national-id', [\App\Http\Controllers\SearchController::class, 'byNationalId'])
    ->middleware('role:teacher,specialist,admin,ministry,institution');
