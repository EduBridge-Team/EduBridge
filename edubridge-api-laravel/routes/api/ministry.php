<?php

use Illuminate\Support\Facades\Route;

// مراجعة الوزارة
Route::get('/ministry/lessons', [\App\Http\Controllers\MinistryController::class, 'lessons'])
    ->middleware('role:ministry,admin');
Route::put('/ministry/lessons/{id}', [\App\Http\Controllers\MinistryController::class, 'review'])
    ->middleware('role:ministry,admin');
Route::get('/ministry/users', [\App\Http\Controllers\MinistryController::class, 'users'])
    ->middleware('role:ministry,admin');
Route::get('/ministry/children', [\App\Http\Controllers\MinistryController::class, 'children'])
    ->middleware('role:ministry,admin');
Route::get('/ministry/stats', [\App\Http\Controllers\MinistryController::class, 'stats'])
    ->middleware('role:ministry,admin');
Route::get('/ministry/statistics', [\App\Http\Controllers\MinistryController::class, 'statistics'])
    ->middleware('role:ministry,admin');
Route::get('/ministry/statistics/progress', [\App\Http\Controllers\MinistryController::class, 'progressStatistics'])
    ->middleware('role:ministry,admin');

// الموافقات الوزارية على الخطط التعليمية
Route::post('/ministry/approvals', [\App\Http\Controllers\MinistryApprovalController::class, 'store'])
    ->middleware('role:teacher,specialist,admin');
Route::get('/ministry/approvals/pending', [\App\Http\Controllers\MinistryApprovalController::class, 'pending'])
    ->middleware('role:teacher,specialist,ministry,admin');
Route::get('/ministry/approvals/notifications', [\App\Http\Controllers\MinistryApprovalController::class, 'notifications'])
    ->middleware('role:teacher,specialist,ministry,admin');
Route::get('/ministry/approvals/child/{childId}/status', [\App\Http\Controllers\MinistryApprovalController::class, 'childStatus'])
    ->middleware('role:parent,teacher,specialist,ministry,admin');
Route::get('/ministry/approvals', [\App\Http\Controllers\MinistryApprovalController::class, 'index'])
    ->middleware('role:teacher,specialist,ministry,admin');
Route::post('/ministry/approvals/{id}/approve', [\App\Http\Controllers\MinistryApprovalController::class, 'approve'])
    ->middleware('role:ministry,admin');
Route::post('/ministry/approvals/{id}/reject', [\App\Http\Controllers\MinistryApprovalController::class, 'reject'])
    ->middleware('role:ministry,admin');

Route::post('/plans/{planId}/evaluate', [\App\Http\Controllers\PlanEvaluationController::class, 'store'])
    ->middleware('role:specialist,admin');
