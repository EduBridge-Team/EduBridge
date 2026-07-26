<?php

// تقديم واجهة الويب من نفس النطاق — SPA
// أي مسار لا يخص الواجهة البرمجية يعيد صفحة التطبيق
// وإن لم تكن الواجهة مرفوعة بعد، نعيد رسالة فحص السيرفر
use Illuminate\Support\Facades\Route;

Route::get('/{any?}', function () {
    $spa = public_path('app.html');
    if (file_exists($spa)) {
        return response()->file($spa);
    }
    return response()->json(['message' => 'EduBridge API شغّال ✅']);
})->where('any', '^(?!api($|/)).*');
