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
use App\Http\Controllers\AssistantController;
use App\Http\Controllers\ConversationController;
use App\Http\Controllers\UserSettingsController;
use App\Http\Controllers\ChildAccessibilityProfileController;
use App\Http\Controllers\TherapyRequestController;
use App\Http\Controllers\SpecialistSuggestionController;
use App\Http\Controllers\HomeworkController;
use App\Http\Controllers\WeeklyReportController;
use App\Http\Controllers\CareTeamController;
use App\Http\Controllers\CaseDiscussionController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\LegacyMobileController;
use App\Http\Controllers\MinistryApprovalController;
use App\Http\Controllers\PlanEvaluationController;

// المصادقة (بدون توكن)
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/google', [AuthController::class, 'google']);

// كل ما يلي يتطلب توكن صالح
Route::middleware('auth.jwt')->group(function () {
    // الملف الشخصي للمستخدم الحالي
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me/password', [AuthController::class, 'changePassword']);
    Route::post('/me/avatar', [AccountController::class, 'uploadAvatar']);
    Route::delete('/me/avatar', [AccountController::class, 'removeAvatar']);
    Route::delete('/me', [AccountController::class, 'destroy']);
    Route::put('/me/specialty', [SpecialistSuggestionController::class, 'updateSpecialty'])
        ->middleware('role:specialist');

    // تفضيلات العرض والمساعد — تتم مزامنتها بين أجهزة المستخدم
    Route::get('/settings', [UserSettingsController::class, 'show']);
    Route::put('/settings', [UserSettingsController::class, 'update']);

    // مساعد «نور» الذكي — محمي ومحدود الطلبات لحماية الأطفال والتكلفة
    Route::post('/assistant/chat', [AssistantController::class, 'chat'])
        ->middleware('throttle:20,1');

    // المحادثات بين ولي الأمر والفريق التعليمي، وبين أعضاء الفريق
    Route::get('/conversation-users', [ConversationController::class, 'users']);
    Route::get('/conversations', [ConversationController::class, 'index']);
    Route::post('/conversations', [ConversationController::class, 'store'])
        ->middleware('throttle:20,1');
    Route::get('/conversations/{conversationId}/messages', [ConversationController::class, 'messages']);
    Route::post('/conversations/{conversationId}/messages', [ConversationController::class, 'send'])
        ->middleware('throttle:60,1');

    // إدارة المستخدمين — لوحة التحكم الإدارية
    // القائمة متاحة للمعلّم/المختص (المعلّمون فقط) لتعيين معلّم للطفل — إصلاح البطاقة 12
    Route::get('/users', [UserController::class, 'index'])
        ->middleware('role:parent,teacher,specialist,admin,ministry,institution');
    Route::put('/users/{id}', [UserController::class, 'update'])
        ->middleware('role:admin');
    // حذف مستخدم (أدمن) — البطاقة 11
    Route::delete('/users/{id}', [UserController::class, 'destroy'])
        ->middleware('role:admin');
    Route::get('/users/{parentId}/children', [LegacyMobileController::class, 'childrenOfParent'])
        ->middleware('role:teacher,specialist,admin,ministry,institution');
    Route::get('/dashboard/stats', [LegacyMobileController::class, 'dashboardStats']);

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

    // توافق التطبيق القديم مع شاشة الأدمن
    Route::get('/admin/verifications', [LegacyMobileController::class, 'adminVerifications'])
        ->middleware('role:admin');
    Route::post('/admin/verifications/{id}/approve', [LegacyMobileController::class, 'approveVerification'])
        ->middleware('role:admin');
    Route::post('/admin/verifications/{id}/reject', [LegacyMobileController::class, 'rejectVerification'])
        ->middleware('role:admin');
    Route::get('/admin/search', [SearchController::class, 'byNationalId'])
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

    // عرض كل المستخدمين للوزارة (عرض فقط)
    Route::get('/ministry/users', [MinistryController::class, 'users'])
        ->middleware('role:ministry,admin');

    // عرض كل الأطفال للوزارة (عرض فقط)
    Route::get('/ministry/children', [MinistryController::class, 'children'])
        ->middleware('role:ministry,admin');

    // إحصائيات لوحة الوزارة (نظرة عامة)
    Route::get('/ministry/stats', [MinistryController::class, 'stats'])
        ->middleware('role:ministry,admin');
    Route::get('/ministry/statistics', [MinistryController::class, 'statistics'])
        ->middleware('role:ministry,admin');
    Route::get('/ministry/statistics/progress', [MinistryController::class, 'progressStatistics'])
        ->middleware('role:ministry,admin');

    // الموافقات الوزارية على الخطط التعليمية
    Route::post('/ministry/approvals', [MinistryApprovalController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/ministry/approvals/pending', [MinistryApprovalController::class, 'pending'])
        ->middleware('role:teacher,specialist,ministry,admin');
    Route::get('/ministry/approvals/notifications', [MinistryApprovalController::class, 'notifications'])
        ->middleware('role:teacher,specialist,ministry,admin');
    Route::get('/ministry/approvals/child/{childId}/status', [MinistryApprovalController::class, 'childStatus'])
        ->middleware('role:parent,teacher,specialist,ministry,admin');
    Route::get('/ministry/approvals', [MinistryApprovalController::class, 'index'])
        ->middleware('role:teacher,specialist,ministry,admin');
    Route::post('/ministry/approvals/{id}/approve', [MinistryApprovalController::class, 'approve'])
        ->middleware('role:ministry,admin');
    Route::post('/ministry/approvals/{id}/reject', [MinistryApprovalController::class, 'reject'])
        ->middleware('role:ministry,admin');

    Route::post('/plans/{planId}/evaluate', [PlanEvaluationController::class, 'store'])
        ->middleware('role:specialist,admin');

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

    // طلبات الدعم التعليمي — ولي الأمر يرسل، ومختص الدعم يراجع ويحدد موعد المتابعة والرابط
    Route::post('/therapy/requests', [TherapyRequestController::class, 'store'])
        ->middleware(['role:parent', 'throttle:10,1']);
    Route::get('/therapy/requests', [TherapyRequestController::class, 'index'])
        ->middleware('role:parent,specialist,admin');
    Route::get('/therapy/requests/child/{childId}/pending', [TherapyRequestController::class, 'pendingForChild'])
        ->middleware('role:parent,specialist,admin');
    Route::put('/therapy/requests/{id}/schedule', [TherapyRequestController::class, 'schedule'])
        ->middleware('role:specialist,admin');
    Route::put('/therapy/requests/{id}/complete', [TherapyRequestController::class, 'complete'])
        ->middleware('role:specialist,admin');
    Route::put('/therapy/requests/{id}/cancel', [TherapyRequestController::class, 'cancel'])
        ->middleware('role:parent,specialist,admin');

    // الأطفال
    Route::post('/children', [ChildController::class, 'store'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::get('/children', [ChildController::class, 'index']);
    Route::get('/children/{id}', [ChildController::class, 'show']);
    Route::put('/children/{id}', [ChildController::class, 'update']);
    Route::delete('/children/{id}', [ChildController::class, 'destroy'])
        ->middleware('role:admin');
    Route::post('/children/{id}/parents', [ChildController::class, 'addParent'])
        ->middleware('role:teacher,specialist,admin');
    Route::post('/children/{id}/assign-teacher', [ChildController::class, 'assignTeacher'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/children/{id}/lessons', [ChildController::class, 'lessons']);
    Route::get('/children/{id}/evaluations', [EvaluationController::class, 'byChild']);

    // اقتراحات متابعة المختصين
    Route::post('/children/{childId}/specialist-suggestions', [SpecialistSuggestionController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/specialist-suggestions', [SpecialistSuggestionController::class, 'index'])
        ->middleware('role:specialist,admin');
    Route::put('/specialist-suggestions/{id}/accept', [SpecialistSuggestionController::class, 'accept'])
        ->middleware('role:specialist,admin');
    Route::put('/specialist-suggestions/{id}/reject', [SpecialistSuggestionController::class, 'reject'])
        ->middleware('role:specialist,admin');

    // الواجبات
    Route::get('/homeworks', [HomeworkController::class, 'index'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::post('/homeworks', [HomeworkController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::post('/homeworks/{id}/submit', [HomeworkController::class, 'submit'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::put('/homeworks/submissions/{submissionId}/grade', [HomeworkController::class, 'grade'])
        ->middleware('role:teacher,specialist,admin');

    // التقارير الأسبوعية
    Route::get('/reports/weekly', [WeeklyReportController::class, 'show'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::get('/reports/weekly/child/{childId}', [WeeklyReportController::class, 'byChild'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::post('/reports/weekly', [WeeklyReportController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');

    // فريق الرعاية — واجهات موحّدة + توافق مع شاشات Flutter الحالية
    Route::get('/children/{childId}/care-team', [CareTeamController::class, 'careTeam'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::post('/children/{childId}/care-team', [CareTeamController::class, 'addCareTeamMember'])
        ->middleware('role:specialist,admin');
    Route::delete('/children/{childId}/care-team/{userId}', [CareTeamController::class, 'removeCareTeamMember'])
        ->middleware('role:specialist,admin');

    Route::get('/children/{childId}/teachers', [CareTeamController::class, 'listTeachers'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::post('/children/{childId}/teachers', [CareTeamController::class, 'addTeacher'])
        ->middleware('role:specialist,admin');
    Route::delete('/children/{childId}/teachers/{teacherId}', [CareTeamController::class, 'removeTeacher'])
        ->middleware('role:specialist,admin');

    Route::get('/children/{childId}/specialists', [CareTeamController::class, 'listSpecialists'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::post('/children/{childId}/specialists', [CareTeamController::class, 'addSpecialist'])
        ->middleware('role:specialist,admin');
    Route::delete('/children/{childId}/specialists/{specialistId}', [CareTeamController::class, 'removeSpecialist'])
        ->middleware('role:specialist,admin');

    // دراسات الحالة التعاونية
    Route::get('/case-discussions', [CaseDiscussionController::class, 'index'])
        ->middleware('role:teacher,specialist,admin');
    Route::post('/case-discussions', [CaseDiscussionController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/case-discussions/{id}', [CaseDiscussionController::class, 'show'])
        ->middleware('role:teacher,specialist,admin');
    Route::post('/case-discussions/{id}/messages', [CaseDiscussionController::class, 'addMessage'])
        ->middleware('role:teacher,specialist,admin');
    Route::put('/case-discussions/{id}/resolve', [CaseDiscussionController::class, 'resolve'])
        ->middleware('role:teacher,specialist,admin');

    // إعدادات التكييف الخاصة بكل طفل — متزامنة بين الأجهزة
    Route::get('/children/{childId}/accessibility-profile', [ChildAccessibilityProfileController::class, 'show']);
    Route::put('/children/{childId}/accessibility-profile', [ChildAccessibilityProfileController::class, 'update']);

    // التقييمات
    Route::get('/evaluations/child/{childId}', [EvaluationController::class, 'byChild']);
    Route::post('/evaluations/child/{childId}', [EvaluationController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');

    // أنواع الإعاقة (قائمة مرجعية)
    Route::get('/disability-types', [DisabilityTypeController::class, 'index']);

    // الدروس
    Route::post('/lessons', [LessonController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::match(['put', 'post'], '/lessons/{id}', [LessonController::class, 'update'])
        ->middleware('role:teacher,specialist,admin');
    Route::delete('/lessons/{id}', [LessonController::class, 'destroy'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/lessons', [LessonController::class, 'index']);
    Route::get('/lessons/search', [LessonController::class, 'search']);
    Route::get('/lessons/{id}', [LessonController::class, 'show']);

    // تقييمات المادة التعليمية (البطاقة 8)
    Route::get('/lessons/{id}/ratings', [RatingController::class, 'index']);
    Route::post('/lessons/{id}/ratings', [RatingController::class, 'store']);
    Route::delete('/ratings/{id}', [RatingController::class, 'destroy']);

    // وسائط الدروس (صور / فيديو / صوت)
    Route::get('/lessons/{id}/media', [MediaController::class, 'index']);
    Route::post('/lessons/{id}/media', [MediaController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::delete('/media/{id}', [MediaController::class, 'destroy'])
        ->middleware('role:teacher,specialist,admin');

    // التقدّم (ولي الأمر يعرض فقط — لا يعدّل)
    Route::post('/progress', [ProgressController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/progress/child/{childId}', [ProgressController::class, 'byChild']);
    Route::get('/progress/child/{childId}/summary', [ProgressController::class, 'summary']);

    // اجتماعات الدعم التعليمي — مع إبقاء المسارات القديمة للتوافق التقني
    Route::get('/therapy/sessions', [SessionController::class, 'index'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::post('/therapy/sessions', [SessionController::class, 'store'])
        ->middleware('role:specialist,admin');
    Route::put('/therapy/sessions/{id}/complete', [SessionController::class, 'complete'])
        ->middleware('role:specialist,admin');

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