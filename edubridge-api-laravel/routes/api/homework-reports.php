<?php

use Illuminate\Support\Facades\Route;

// الواجبات
Route::get('/homeworks', [\App\Http\Controllers\HomeworkController::class, 'index'])
    ->middleware('role:parent,teacher,specialist,admin');
Route::post('/homeworks', [\App\Http\Controllers\HomeworkController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::post('/homeworks/{id}/submit', [\App\Http\Controllers\HomeworkController::class, 'submit'])
    ->middleware('role:parent,teacher,specialist,admin');
Route::put('/homeworks/submissions/{submissionId}/grade', [\App\Http\Controllers\HomeworkController::class, 'grade'])
    ->middleware('role:teacher,specialist,admin');

// التقارير الأسبوعية
Route::get('/reports/weekly', [\App\Http\Controllers\WeeklyReportController::class, 'show'])
    ->middleware('role:parent,teacher,specialist,admin');
Route::get('/reports/weekly/child/{childId}', [\App\Http\Controllers\WeeklyReportController::class, 'byChild'])
    ->middleware(['role:parent,teacher,specialist,admin', 'child.access']);
Route::post('/reports/weekly', [\App\Http\Controllers\WeeklyReportController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::post('/reports/weekly/specialist', [\App\Http\Controllers\WeeklyReportController::class, 'storeSpecialist'])
    ->middleware('role:specialist,admin');
