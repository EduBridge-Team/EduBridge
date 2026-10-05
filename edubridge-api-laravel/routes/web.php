<?php

use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\PreventRequestForgery;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\Support\Facades\Route;
use Illuminate\View\Middleware\ShareErrorsFromSession;

// api.edubridge.win is an API-only host in production. Keep a tiny root status
// response for operators, but do not start a browser session or emit CSRF/session
// cookies for this public GET. Unknown non-/api paths intentionally fall through
// to Laravel's normal 404 instead of returning the API status payload; this avoids
// making scanner probes such as /actuator/health look like real health endpoints.
Route::get('/', function () {
    return response()->json(['message' => 'EduBridge API شغّال ✅']);
})->withoutMiddleware([
    EncryptCookies::class,
    AddQueuedCookiesToResponse::class,
    StartSession::class,
    ShareErrorsFromSession::class,
    PreventRequestForgery::class,
]);
