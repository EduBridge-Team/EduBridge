<?php

use Illuminate\Support\Facades\Route;

// الأطفال
Route::post('/children', [\App\Http\Controllers\ChildController::class, 'store'])
    ->middleware('role:parent,admin');
Route::get('/children', [\App\Http\Controllers\ChildController::class, 'index']);
Route::get('/children/{id}', [\App\Http\Controllers\ChildController::class, 'show'])
    ->middleware('child.access');
Route::put('/children/{id}', [\App\Http\Controllers\ChildController::class, 'update'])
    ->middleware('child.access');
Route::delete('/children/{id}', [\App\Http\Controllers\ChildController::class, 'destroy'])
    ->middleware('role:admin');
Route::post('/children/{id}/parents', [\App\Http\Controllers\ChildRelationController::class, 'addParent'])
    ->middleware('role:admin');
Route::post('/children/{id}/assign-teacher', [\App\Http\Controllers\ChildRelationController::class, 'assignTeacher'])
    ->middleware('role:admin');
Route::get('/children/{id}/lessons', [\App\Http\Controllers\ChildLessonController::class, 'lessons'])
    ->middleware('child.access');
Route::get('/children/{id}/evaluations', [\App\Http\Controllers\EvaluationController::class, 'byChild'])
    ->middleware('child.access');

// فريق الرعاية
Route::get('/children/{childId}/care-team', [\App\Http\Controllers\CareTeamController::class, 'careTeam'])
    ->middleware(['role:parent,teacher,specialist,admin', 'child.access']);
Route::post('/children/{childId}/care-team', [\App\Http\Controllers\CareTeamController::class, 'addCareTeamMember'])
    ->middleware('role:specialist,admin');
Route::delete('/children/{childId}/care-team/{userId}', [\App\Http\Controllers\CareTeamController::class, 'removeCareTeamMember'])
    ->middleware('role:specialist,admin');

Route::get('/children/{childId}/teachers', [\App\Http\Controllers\CareTeamController::class, 'listTeachers'])
    ->middleware(['role:parent,teacher,specialist,admin', 'child.access']);
Route::post('/children/{childId}/teachers', [\App\Http\Controllers\CareTeamController::class, 'addTeacher'])
    ->middleware('role:specialist,admin');
Route::delete('/children/{childId}/teachers/{teacherId}', [\App\Http\Controllers\CareTeamController::class, 'removeTeacher'])
    ->middleware('role:specialist,admin');

Route::get('/children/{childId}/specialists', [\App\Http\Controllers\CareTeamController::class, 'listSpecialists'])
    ->middleware(['role:parent,teacher,specialist,admin', 'child.access']);
Route::post('/children/{childId}/specialists', [\App\Http\Controllers\CareTeamController::class, 'addSpecialist'])
    ->middleware('role:specialist,admin');
Route::delete('/children/{childId}/specialists/{specialistId}', [\App\Http\Controllers\CareTeamController::class, 'removeSpecialist'])
    ->middleware('role:specialist,admin');
