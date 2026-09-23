<?php

// مسارات الـ API
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ChildController;
use App\Http\Controllers\ChildLessonController;
use App\Http\Controllers\ChildRelationController;
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
use App\Http\Controllers\LearningSupportRequestController;
use App\Http\Controllers\LearningSupportMeetingController;
use App\Http\Controllers\SpecialistSuggestionController;
use App\Http\Controllers\HomeworkController;
use App\Http\Controllers\WeeklyReportController;
use App\Http\Controllers\CareTeamController;
use App\Http\Controllers\CaseDiscussionController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\LegacyMobileController;
use App\Http\Controllers\MinistryApprovalController;
use App\Http\Controllers\PlanEvaluationController;
use App\Http\Controllers\DashboardController;

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
