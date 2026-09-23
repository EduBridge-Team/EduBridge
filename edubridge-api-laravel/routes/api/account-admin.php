<?php

use Illuminate\Support\Facades\Route;

// إحصائيات لوحة التحكم — النطاق محسوب حسب صلاحية المستخدم
    Route::get('/dashboard/stats', [\App\Http\Controllers\DashboardController::class, 'stats']);

    // الملف الشخصي للمستخدم الحالي
    Route::get('/me', [\App\Http\Controllers\AccountController::class, 'me']);
    Route::put('/me/password', [\App\Http\Controllers\AccountController::class, 'changePassword'])
        ->middleware('throttle:10,1');
    Route::post('/me/avatar', [\App\Http\Controllers\AccountController::class, 'uploadAvatar']);
    Route::delete('/me/avatar', [\App\Http\Controllers\AccountController::class, 'removeAvatar']);
    Route::delete('/me', [\App\Http\Controllers\AccountController::class, 'destroy']);
    Route::put('/me/specialty', [\App\Http\Controllers\SpecialistSuggestionController::class, 'updateSpecialty'])
        ->middleware('role:specialist');

    // تفضيلات العرض والمساعد — تتم مزامنتها بين أجهزة المستخدم
    Route::get('/settings', [\App\Http\Controllers\UserSettingsController::class, 'show']);
    Route::put('/settings', [\App\Http\Controllers\UserSettingsController::class, 'update']);

    // مساعد «نور» الذكي — محمي ومحدود الطلبات لحماية الأطفال والتكلفة
    Route::post('/assistant/chat', [\App\Http\Controllers\AssistantController::class, 'chat'])
        ->middleware('throttle:20,1');

    // المحادثات بين ولي الأمر والفريق التعليمي، وبين أعضاء الفريق
    Route::get('/conversation-users', [\App\Http\Controllers\ConversationController::class, 'users']);
    Route::get('/conversations', [\App\Http\Controllers\ConversationController::class, 'index']);
    Route::post('/conversations', [\App\Http\Controllers\ConversationController::class, 'store'])
        ->middleware('throttle:20,1');
    Route::get('/conversations/{conversationId}/messages', [\App\Http\Controllers\ConversationController::class, 'messages']);
    Route::post('/conversations/{conversationId}/messages', [\App\Http\Controllers\ConversationController::class, 'send'])
        ->middleware('throttle:60,1');

    // إدارة المستخدمين — لوحة التحكم الإدارية
    // القائمة متاحة للمعلّم/المختص (المعلّمون فقط) لتعيين معلّم للطفل — إصلاح البطاقة 12
    Route::get('/users', [\App\Http\Controllers\UserController::class, 'index'])
        ->middleware('role:parent,teacher,specialist,admin,ministry,institution');
    Route::put('/users/{id}', [\App\Http\Controllers\UserController::class, 'update'])
        ->middleware('role:admin');
    // حذف مستخدم (أدمن) — البطاقة 11
    Route::delete('/users/{id}', [\App\Http\Controllers\UserController::class, 'destroy'])
        ->middleware('role:admin');
    // رفع الملفات (صور الهوية/الشهادات/مستندات القرابة)
    Route::post('/uploads', [\App\Http\Controllers\UploadController::class, 'store'])->middleware('throttle:20,1');
    Route::get('/private-files/user/{userId}/{filename}', [\App\Http\Controllers\UploadController::class, 'show'])
        ->where('filename', '[A-Za-z0-9._-]+');
    Route::get('/private-files/child/{childId}/{filename}', [\App\Http\Controllers\UploadController::class, 'showChild'])
        ->where('filename', '[A-Za-z0-9._-]+');

    // توثيق الهوية — المستخدم نفسه + الأدمن (البطاقات 1، 4، 9)
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

    // الشهادات (البطاقة 9)
    Route::get('/certificates', [\App\Http\Controllers\CertificateController::class, 'index']);
    Route::post('/certificates', [\App\Http\Controllers\CertificateController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::put('/certificates/{id}', [\App\Http\Controllers\CertificateController::class, 'review'])
        ->middleware('role:admin');
    Route::delete('/certificates/{id}', [\App\Http\Controllers\CertificateController::class, 'destroy']);

    // البحث برقم الهوية — الموظفون فقط (البطاقة 2)
    Route::get('/search/national-id', [\App\Http\Controllers\SearchController::class, 'byNationalId'])
        ->middleware('role:teacher,specialist,admin,ministry,institution');

    // مراجعة المناهج من الوزارة (البطاقة 3)
    Route::get('/ministry/lessons', [\App\Http\Controllers\MinistryController::class, 'lessons'])
        ->middleware('role:ministry,admin');
    Route::put('/ministry/lessons/{id}', [\App\Http\Controllers\MinistryController::class, 'review'])
        ->middleware('role:ministry,admin');

    // عرض كل المستخدمين للوزارة (عرض فقط)
    Route::get('/ministry/users', [\App\Http\Controllers\MinistryController::class, 'users'])
        ->middleware('role:ministry,admin');

    // عرض كل الأطفال للوزارة (عرض فقط)
    Route::get('/ministry/children', [\App\Http\Controllers\MinistryController::class, 'children'])
        ->middleware('role:ministry,admin');

    // إحصائيات لوحة الوزارة (نظرة عامة)
    Route::get('/ministry/stats', [\App\Http\Controllers\MinistryController::class, 'stats'])
        ->middleware('role:ministry,admin');
    Route::get('/ministry/statistics', [\App\Http\Controllers\MinistryController::class, 'statistics'])
        ->middleware('role:ministry,admin');
    Route::get('/ministry/statistics/progress', [\App\Http\Controllers\MinistryController::class, 'progressStatistics'])
        ->middleware('role:ministry,admin');

    // الموافقات الوزارية على الخطط التعليمية
    Route::post('/ministry/approvals', [\App\Http\Controllers\MinistryApprovalController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/ministry/approvals/pending', [\App\Http\Controllers\MinistryApprovalController::class, 'pending'])
        ->middleware('role:teacher,specialist,ministry,admin');
    Route::get('/ministry/approvals/notifications', [\App\Http\Controllers\MinistryApprovalController::class, 'notifications'])
        ->middleware('role:teacher,specialist,ministry,admin');
    Route::get('/ministry/approvals/child/{childId}/status', [\App\Http\Controllers\MinistryApprovalController::class, 'childStatus'])
        ->middleware('role:parent,teacher,specialist,ministry,admin');
    Route::get('/ministry/approvals', [\App\Http\Controllers\MinistryApprovalController::class, 'index'])
        ->middleware('role:teacher,specialist,ministry,admin');
    Route::post('/ministry/approvals/{id}/approve', [\App\Http\Controllers\MinistryApprovalController::class, 'approve'])
        ->middleware('role:ministry,admin');
    Route::post('/ministry/approvals/{id}/reject', [\App\Http\Controllers\MinistryApprovalController::class, 'reject'])
        ->middleware('role:ministry,admin');

    Route::post('/plans/{planId}/evaluate', [\App\Http\Controllers\PlanEvaluationController::class, 'store'])
        ->middleware('role:specialist,admin');
