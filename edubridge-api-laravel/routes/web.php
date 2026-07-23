<?php

// يقدّم واجهة الويب (SPA) من نفس النطاق — أي مسار غير API يعيد صفحة التطبيق
// إن لم تكن الواجهة مرفوعة (app.html غير موجود) نعيد رسالة فحص السيرفر
use Illuminate\Support\Facades\Route;

Route::get('/{any?}', function () {
    $spa = public_path('app.html');
    if (file_exists($spa)) {
        return response()->file($spa);
    }
    return response()->json(['message' => 'EduBridge API شغّال ✅']);
})->where('any', '^(?!api($|/)).*');
