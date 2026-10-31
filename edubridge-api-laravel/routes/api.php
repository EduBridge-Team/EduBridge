<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\InstitutionContextController;
use App\Http\Controllers\InstitutionTeacherInvitationController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    try {
        \Illuminate\Support\Facades\DB::select('select 1');
        $statusCode = 200;
    } catch (\Throwable $e) {
        $statusCode = 503;
    }

    return response()->json([
        'status' => $statusCode === 200 ? 'ok' : 'degraded',
    ], $statusCode);
})->middleware('throttle:120,1');

Route::get('/institutions/{slug}/context', [InstitutionContextController::class, 'show'])
    ->where('slug', '[a-z0-9][a-z0-9-]{1,79}')
    ->middleware('throttle:120,1');

// المصادقة (بدون توكن)
Route::post('/auth/register', [AuthController::class, 'register'])
    ->middleware('throttle:auth-register');
Route::post('/auth/login', [AuthController::class, 'login'])
    ->middleware('throttle:auth-login');
Route::post('/auth/google', [AuthController::class, 'google'])
    ->middleware('throttle:auth-login');
Route::post('/auth/logout', [AuthController::class, 'logout'])
    ->middleware(['auth.jwt', 'api.abuse']);
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword'])
    ->middleware('throttle:auth-recovery');
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword'])
    ->middleware('throttle:auth-recovery');
Route::post('/auth/resend-verification', [AuthController::class, 'resendEmailVerification'])
    ->middleware('throttle:auth-recovery');
Route::get('/auth/verify-email', [AuthController::class, 'verifyEmail'])
    ->middleware('throttle:20,1');

Route::get('/private-files/lesson/{lessonId}/{filename}', [\App\Http\Controllers\LessonFileController::class, 'show'])
    ->name('lesson.file')->middleware(['signed:relative', 'throttle:300,1']);

Route::post('/school/director-invitations/accept', [\App\Http\Controllers\SchoolDirectorInvitationController::class, 'accept'])
    ->middleware(['auth.jwt', 'api.abuse', 'throttle:10,1']);

// كل ما يلي يتطلب توكن صالح، تحقق هوية، وحماية موحدة من الإغراق.
Route::middleware(['auth.jwt', 'identity.verified', 'api.abuse'])->group(function () {
    Route::get('/me/director-schools', [\App\Http\Controllers\MySchoolDirectorAssignmentsController::class, 'index'])
        ->middleware('throttle:60,1');
    Route::patch('/school/internal-identities/{identity}', [\App\Http\Controllers\SchoolInternalLifecycleController::class, 'update'])
        ->whereNumber('identity')->middleware('throttle:10,1');
    Route::get('/admin/schools/{school}/director-invitations', [\App\Http\Controllers\SchoolDirectorInvitationController::class, 'index'])
        ->whereNumber('school')->middleware('throttle:60,1');
    Route::post('/admin/schools/{school}/director-invitations', [\App\Http\Controllers\SchoolDirectorInvitationController::class, 'store'])
        ->whereNumber('school')->middleware('throttle:10,1');
    Route::delete('/admin/schools/{school}/director-invitations/{invitation}', [\App\Http\Controllers\SchoolDirectorInvitationController::class, 'revoke'])
        ->whereNumber('school')->whereNumber('invitation')->middleware('throttle:10,1');
    Route::get('/admin/schools', [\App\Http\Controllers\SchoolAdministrationDirectoryController::class, 'index'])->middleware('throttle:60,1');
    Route::get('/admin/schools/{school}/management-history', [\App\Http\Controllers\SchoolAdministrationDirectoryController::class, 'history'])
        ->whereNumber('school')->middleware('throttle:60,1');
    Route::get('/school/transfers/incoming', [\App\Http\Controllers\SchoolTransferDestinationController::class, 'index'])->middleware('throttle:60,1');
    Route::post('/school/transfers/{transfer}/decision', [\App\Http\Controllers\SchoolTransferDestinationController::class, 'decide'])->whereNumber('transfer')->middleware('throttle:10,1');
    Route::post('/school/transfers', [\App\Http\Controllers\SchoolTransferConsentController::class, 'create'])->middleware('throttle:10,1');
    Route::get('/parent/children/{child}/transfers', [\App\Http\Controllers\SchoolTransferConsentController::class, 'guardianIndex'])->whereNumber('child')->middleware(['role:parent', 'throttle:60,1']);
    Route::post('/parent/children/{child}/transfers/{transfer}/decision', [\App\Http\Controllers\SchoolTransferConsentController::class, 'guardianDecision'])->whereNumber('child')->whereNumber('transfer')->middleware(['role:parent', 'throttle:10,1']);
    Route::get('/school/annual-promotion/roster', [\App\Http\Controllers\SchoolAnnualPromotionController::class, 'roster'])->middleware('throttle:60,1');
    Route::get('/school/annual-promotion/transfer-schools', [\App\Http\Controllers\SchoolAnnualPromotionController::class, 'destinations'])->middleware('throttle:60,1');
    Route::post('/school/annual-promotion/preview', [\App\Http\Controllers\SchoolAnnualPromotionController::class, 'preview'])->middleware('throttle:20,1');
    Route::post('/school/annual-promotion/approve', [\App\Http\Controllers\SchoolAnnualPromotionController::class, 'approve'])->middleware('throttle:10,1');
    Route::get('/school/annual-promotion/history', [\App\Http\Controllers\SchoolAnnualPromotionController::class, 'history'])->middleware('throttle:60,1');
    Route::get('/school/annual-promotion/operations/{operation}', [\App\Http\Controllers\SchoolAnnualPromotionController::class, 'operation'])->middleware('throttle:60,1');
    Route::get('/student/me', [\App\Http\Controllers\StudentSelfController::class, 'show']);
    Route::get('/student/timetable', [\App\Http\Controllers\StudentSelfController::class, 'timetable']);
    Route::get('/student/homework-progress', [\App\Http\Controllers\StudentSelfController::class, 'homeworkProgress']);
    Route::get('/student/homeworks', [\App\Http\Controllers\StudentSelfController::class, 'homeworks']);
    Route::post('/student/homeworks/{homework}/submit', [\App\Http\Controllers\StudentHomeworkSubmitController::class, 'store'])->whereNumber('homework');
    Route::match(['GET', 'POST', 'PATCH', 'PUT', 'DELETE'], '/school/operations/{action}', [\App\Http\Controllers\SchoolOperationsController::class, 'handle'])->middleware('throttle:60,1');
    Route::get('/school/delegation', [\App\Http\Controllers\SchoolDelegationController::class, 'show'])->middleware('throttle:60,1');
    Route::patch('/school/deputies/{assignment}/permissions', [\App\Http\Controllers\SchoolDelegationController::class, 'update'])
        ->whereNumber('assignment')->middleware('throttle:10,1');
    Route::get('/school/internal-domain', [\App\Http\Controllers\SchoolInternalDomainController::class, 'show'])
        ->middleware('throttle:120,1');
    Route::post('/school/internal-domain/confirm', [\App\Http\Controllers\SchoolInternalDomainController::class, 'confirm'])
        ->middleware('throttle:10,1');
    Route::post('/school/internal-identities', [\App\Http\Controllers\SchoolInternalAccountController::class, 'store'])
        ->middleware('throttle:10,1');
    Route::get('/school/internal-identities', [\App\Http\Controllers\SchoolInternalIdentityDirectoryController::class, 'index'])
        ->middleware('throttle:60,1');
    Route::get('/school/deputies', [\App\Http\Controllers\SchoolDeputyManagementController::class, 'index'])
        ->middleware('throttle:60,1');
    Route::post('/school/deputies', [\App\Http\Controllers\SchoolDeputyManagementController::class, 'store'])
        ->middleware('throttle:10,1');
    Route::delete('/school/deputies/{assignment}', [\App\Http\Controllers\SchoolDeputyManagementController::class, 'revoke'])
        ->whereNumber('assignment')->middleware('throttle:10,1');
    Route::get('/school/context', [\App\Http\Controllers\SchoolContextController::class, 'show'])
        ->middleware('throttle:120,1');
    Route::get('/school/academic', [\App\Http\Controllers\SchoolAcademicController::class, 'index'])
        ->middleware(['role:school', 'throttle:120,1']);
    Route::post('/school/academic/years', [\App\Http\Controllers\SchoolAcademicController::class, 'storeYear'])
        ->middleware(['role:school', 'throttle:20,1']);
    Route::post('/school/academic/grades', [\App\Http\Controllers\SchoolAcademicController::class, 'storeGrade'])
        ->middleware(['role:school', 'throttle:20,1']);
    Route::post('/school/academic/sections', [\App\Http\Controllers\SchoolAcademicController::class, 'storeSection'])
        ->middleware(['role:school', 'throttle:20,1']);
    Route::get('/school/academic/curriculum', [\App\Http\Controllers\SchoolCurriculumCatalogController::class, 'index'])
        ->middleware(['role:school', 'throttle:120,1']);
    Route::get('/school/enrollment-options', [\App\Http\Controllers\SchoolEnrollmentOptionsController::class, 'index'])
        ->middleware(['role:school', 'throttle:120,1']);
    Route::get('/parent/enrollment-schools', [\App\Http\Controllers\GuardianSchoolRequestController::class, 'schools'])
        ->middleware(['role:parent', 'throttle:60,1']);
    Route::post('/parent/children/{child}/enrollment-requests', [\App\Http\Controllers\GuardianSchoolRequestController::class, 'submit'])
        ->whereNumber('child')->middleware(['role:parent', 'throttle:10,1']);
    Route::get('/parent/children/{child}/enrollment-requests', [\App\Http\Controllers\GuardianEnrollmentHistoryController::class, 'index'])
        ->whereNumber('child')->middleware(['role:parent', 'throttle:60,1']);
    Route::post('/parent/children/{child}/enrollment-requests/{request}/cancel', [\App\Http\Controllers\GuardianEnrollmentCancellationController::class, 'cancel'])
        ->whereNumber('child')->whereNumber('request')->middleware(['role:parent', 'throttle:10,1']);
    Route::get('/school/enrollment-requests', [\App\Http\Controllers\SchoolEnrollmentInboxController::class, 'index'])
        ->middleware(['role:school', 'throttle:60,1']);
    Route::post('/school/enrollment-requests/{request}/decision', [\App\Http\Controllers\SchoolEnrollmentDecisionController::class, 'decide'])
        ->whereNumber('request')->middleware(['role:school', 'throttle:20,1']);
    Route::get('/interactive-lesson-drafts', [\App\Http\Controllers\InteractiveLessonDraftController::class, 'index'])
        ->middleware(['role:teacher,specialist', 'throttle:60,1']);
    Route::post('/interactive-lesson-drafts', [\App\Http\Controllers\InteractiveLessonDraftController::class, 'store'])
        ->middleware(['role:teacher,specialist', 'throttle:20,1']);
    Route::put('/interactive-lesson-drafts/{draft}', [\App\Http\Controllers\InteractiveLessonDraftController::class, 'update'])
        ->whereNumber('draft')->middleware(['role:teacher,specialist', 'throttle:20,1']);
    require __DIR__ . '/api/account-admin.php';
    require __DIR__ . '/api/support-children.php';
    require __DIR__ . '/api/learning-content.php';
    Route::post('/teacher-invitations/accept', [InstitutionTeacherInvitationController::class, 'accept'])->middleware('throttle:10,1');
    require __DIR__ . '/api/institutions.php';
});
