<?php

use App\Http\Controllers\InstitutionAcademicController;
use App\Http\Controllers\InstitutionAttendanceController;
use App\Http\Controllers\InstitutionSchoolController;
use App\Http\Controllers\InstitutionTimetableController;
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

        Route::prefix('/schools/{school}/attendance')->whereNumber('school')->group(function () {
            Route::get('/', [InstitutionAttendanceController::class, 'index']);
            Route::get('/report', [InstitutionAttendanceController::class, 'report']);
            Route::post('/', [InstitutionAttendanceController::class, 'store']);
            Route::get('/{attendanceSession}', [InstitutionAttendanceController::class, 'show'])->whereNumber('attendanceSession');
            Route::put('/{attendanceSession}/records', [InstitutionAttendanceController::class, 'mark'])->whereNumber('attendanceSession');
        });

        Route::prefix('/schools/{school}/timetable')->whereNumber('school')->group(function () {
            Route::get('/', [InstitutionTimetableController::class, 'index']);
            Route::post('/', [InstitutionTimetableController::class, 'store']);
            Route::delete('/{entry}', [InstitutionTimetableController::class, 'destroy'])->whereNumber('entry');
        });
    });
