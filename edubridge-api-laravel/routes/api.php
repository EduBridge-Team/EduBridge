<?php

use App\Http\Controllers\AuthController;
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
    require __DIR__ . '/api/account-admin.php';
    require __DIR__ . '/api/support-children.php';
    require __DIR__ . '/api/learning-content.php';
});
