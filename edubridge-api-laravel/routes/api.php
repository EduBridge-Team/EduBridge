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

// كل ما يلي يتطلب توكن صالح، تحقق هوية، وحماية موحدة من الإغراق.
Route::middleware(['auth.jwt', 'identity.verified', 'api.abuse'])->group(function () {
    Route::get('/school/context', [\App\Http\Controllers\SchoolContextController::class, 'show'])
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
    require __DIR__ . '/api/account-admin.php';
    require __DIR__ . '/api/support-children.php';
    require __DIR__ . '/api/learning-content.php';
    Route::post('/teacher-invitations/accept', [InstitutionTeacherInvitationController::class, 'accept'])->middleware('throttle:10,1');
    require __DIR__ . '/api/institutions.php';
});
