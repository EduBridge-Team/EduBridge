<?php

use App\Http\Controllers\InstitutionAcademicController;
use App\Http\Controllers\InstitutionSchoolController;
use Illuminate\Support\Facades\Route;

Route::prefix('/institutions/{organizationSlug}')
    ->where(['organizationSlug' => '[a-z0-9][a-z0-9-]{1,79}'])
    ->middleware('organization.member:owner,admin,school_admin')
    ->group(function () {
        Route::get('/schools', [InstitutionSchoolController::class, 'index']);
        Route::post('/schools', [InstitutionSchoolController::class, 'store']);
        Route::get('/schools/{school}', [InstitutionSchoolController::class, 'show'])->whereNumber('school');
        Route::patch('/schools/{school}', [InstitutionSchoolController::class, 'update'])->whereNumber('school');
        Route::delete('/schools/{school}', [InstitutionSchoolController::class, 'destroy'])->whereNumber('school');

        Route::prefix('/schools/{school}/academic')->whereNumber('school')->group(function () {
            Route::get('/', [InstitutionAcademicController::class, 'overview']);
            Route::post('/years', [InstitutionAcademicController::class, 'storeAcademicYear']);
            Route::post('/years/{academicYear}/terms', [InstitutionAcademicController::class, 'storeTerm'])->whereNumber('academicYear');
            Route::post('/grades', [InstitutionAcademicController::class, 'storeGrade']);
            Route::post('/sections', [InstitutionAcademicController::class, 'storeSection']);
            Route::post('/subjects', [InstitutionAcademicController::class, 'storeSubject']);
            Route::post('/teacher-assignments', [InstitutionAcademicController::class, 'assignTeacher']);
            Route::post('/student-enrollments', [InstitutionAcademicController::class, 'enrollStudent']);
        });
    });
