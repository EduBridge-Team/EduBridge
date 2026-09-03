<?php

// مسارات الـ API
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ChildController;
use App\Http\Controllers\LessonController;
use App\Http\Controllers\ProgressController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\DisabilityTypeController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\EvaluationController;
use App\Http\Controllers\UploadController;
use App\Http\Controllers\VerificationController;
use App\Http\Controllers\CertificateController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\MinistryController;
use App\Http\Controllers\RatingController;
use App\Http\Controllers\SupportController;
use App\Http\Controllers\ConsultationController;

// المصادقة (بدون توكن)
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/google', [AuthController::class, 'google']);

// كل ما يلي يتطلب توكن صالح
Route::middleware('auth.jwt')->group(function () {
    // مثال على مسار محمي — يعيد حمولة التوكن
    Route::get('/me', [AuthController::class, 'me']);

    // إدارة المستخدمين — لوحة التحكم الإدارية
    // القائمة متاحة للمعلّم/المختص (المعلّمون فقط) لتعيين معلّم للطفل — إصلاح البطاقة 12
    Route::get('/users', [UserController::class, 'index'])
        ->middleware('role:teacher,specialist,admin,institution');
    Route::put('/users/{id}', [UserController::class, 'update'])
        ->middleware('role:admin');
    // حذف مستخدم (أدمن) — البطاقة 11
    Route::delete('/users/{id}', [UserController::class, 'destroy'])
        ->middleware('role:admin');

    // رفع الملفات (صور الهوية/الشهادات/مستندات القرابة)
    Route::post('/uploads', [UploadController::class, 'store']);

    // توثيق الهوية — المستخدم نفسه + الأدمن (البطاقات 1، 4، 9)
    Route::post('/me/identity', [VerificationController::class, 'submitMine']);
    Route::get('/me/verification', [VerificationController::class, 'myStatus']);
    Route::get('/verifications/users', [VerificationController::class, 'users'])
        ->middleware('role:admin');
    Route::put('/verifications/users/{id}', [VerificationController::class, 'reviewUser'])
        ->middleware('role:admin');
    Route::get('/verifications/children', [VerificationController::class, 'children'])
        ->middleware('role:admin');
    Route::put('/verifications/children/{id}', [VerificationController::class, 'reviewChild'])
        ->middleware('role:admin');

    // الشهادات (البطاقة 9)
    Route::get('/certificates', [CertificateController::class, 'index']);
    Route::post('/certificates', [CertificateController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::put('/certificates/{id}', [CertificateController::class, 'review'])
        ->middleware('role:admin');
    Route::delete('/certificates/{id}', [CertificateController::class, 'destroy']);

    // البحث برقم الهوية — الموظفون فقط (البطاقة 2)
    Route::get('/search/national-id', [SearchController::class, 'byNationalId'])
        ->middleware('role:teacher,specialist,admin,ministry,institution');

    // مراجعة المناهج من الوزارة (البطاقة 3)
    Route::get('/ministry/lessons', [MinistryController::class, 'lessons'])
        ->middleware('role:ministry,admin');
    Route::put('/ministry/lessons/{id}', [MinistryController::class, 'review'])
        ->middleware('role:ministry,admin');

    // الدعم الفني والشكاوى (البطاقة 11)
    Route::get('/support', [SupportController::class, 'index']);
    Route::post('/support', [SupportController::class, 'store']);
    Route::put('/support/{id}', [SupportController::class, 'update'])
        ->middleware('role:admin');

    // دراسة الحالة مع المختصين (البطاقة 7)
    Route::get('/consultations', [ConsultationController::class, 'index']);
    Route::post('/consultations', [ConsultationController::class, 'store']);
    Route::get('/consultations/{id}', [ConsultationController::class, 'show']);
    Route::put('/consultations/{id}', [ConsultationController::class, 'update'])
        ->middleware('role:specialist,admin');
    Route::post('/consultations/{id}/notes', [ConsultationController::class, 'addNote'])
        ->middleware('role:specialist,admin');

    // الأطفال
    Route::post('/children', [ChildController::class, 'store'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::get('/children', [ChildController::class, 'index']);
    Route::get('/children/{id}', [ChildController::class, 'show']);
    Route::put('/children/{id}', [ChildController::class, 'update']);
    Route::post('/children/{id}/parents', [ChildController::class, 'addParent'])
        ->middleware('role:teacher,specialist,admin');
    Route::post('/children/{id}/assign-teacher', [ChildController::class, 'assignTeacher'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/children/{id}/lessons', [ChildController::class, 'lessons']);
    Route::get('/children/{id}/evaluations', [EvaluationController::class, 'byChild']);

    // التقييمات
    Route::get('/evaluations/child/{childId}', [EvaluationController::class, 'byChild']);
    Route::post('/evaluations/child/{childId}', [EvaluationController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');

    // أنواع الإعاقة (قائمة مرجعية)
    Route::get('/disability-types', [DisabilityTypeController::class, 'index']);

    // الدروس
    Route::post('/lessons', [LessonController::class, 'store'])
        ->middleware('role:teacher,admin');
    Route::get('/lessons', [LessonController::class, 'index']);
    Route::get('/lessons/{id}', [LessonController::class, 'show']);

    // تقييمات المادة التعليمية (البطاقة 8)
    Route::get('/lessons/{id}/ratings', [RatingController::class, 'index']);
    Route::post('/lessons/{id}/ratings', [RatingController::class, 'store']);
    Route::delete('/ratings/{id}', [RatingController::class, 'destroy']);

    // وسائط الدروس (صور / فيديو / صوت)
    Route::get('/lessons/{id}/media', [MediaController::class, 'index']);
    Route::post('/lessons/{id}/media', [MediaController::class, 'store'])
        ->middleware('role:teacher,admin');
    Route::delete('/media/{id}', [MediaController::class, 'destroy'])
        ->middleware('role:teacher,admin');

    // التقدّم (ولي الأمر يعرض فقط — لا يعدّل)
    Route::post('/progress', [ProgressController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/progress/child/{childId}', [ProgressController::class, 'byChild']);
    Route::get('/progress/child/{childId}/summary', [ProgressController::class, 'summary']);

    // الجلسات العلاجية (مختص / أدمن)
    Route::get('/sessions', [SessionController::class, 'index'])
        ->middleware('role:specialist,admin');
    Route::post('/sessions', [SessionController::class, 'store'])
        ->middleware('role:specialist,admin');
    Route::get('/sessions/child/{childId}', [SessionController::class, 'byChild'])
        ->middleware('role:specialist,admin,teacher');
    Route::put('/sessions/{id}', [SessionController::class, 'update'])
        ->middleware('role:specialist,admin');

    // الإشعارات — لكل مستخدم إشعاراته
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread/count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications', [NotificationController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    // نقبل PUT و POST لتوافق الموقع والتطبيق معاً
    Route::match(['put', 'post'], '/notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markRead']);
});
