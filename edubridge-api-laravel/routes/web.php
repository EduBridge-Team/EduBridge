<?php

// مسار فحص إن السيرفر شغّال — نفس رسالة النسخة القديمة
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json(['message' => 'EduBridge API شغّال ✅']);
});
