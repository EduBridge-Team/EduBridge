<?php

use App\Http\Controllers\InstitutionAcademicController;
use App\Http\Controllers\InstitutionTeacherInvitationController;
use App\Http\Controllers\InstitutionTeacherMembershipController;
use App\Http\Controllers\InstitutionAttendanceController;
use App\Http\Controllers\InstitutionCurriculumController;
use App\Http\Controllers\InstitutionParticipantController;
use App\Http\Controllers\InstitutionManagementReportController;
use App\Http\Controllers\InstitutionStudentEnrollmentController;
use App\Http\Controllers\InstitutionSchoolController;
use App\Http\Controllers\InstitutionSubstitutionController;
use App\Http\Controllers\InstitutionTimetableController;
use Illuminate\Support\Facades\Route;

Route::prefix('/institutions/{organizationSlug}')
    ->where(['organizationSlug' => '[a-z0-9][a-z0-9-]{1,79}'])
    ->middleware('organization.member:owner,admin,school_admin')
    ->group(function () {
        Route::get('/management-report', [InstitutionManagementReportController::class, 'index']);
        Route::get('/teachers', [InstitutionTeacherMembershipController::class, 'index']);
        Route::patch('/teachers/{teacher}', [InstitutionTeacherMembershipController::class, 'update'])->whereNumber('teacher');
        Route::get('/teacher-invitations', [InstitutionTeacherInvitationController::class, 'index']);
        Route::post('/teacher-invitations', [InstitutionTeacherInvitationController::class, 'store'])->middleware('throttle:10,1');
        Route::delete('/teacher-invitations/{invitation}', [InstitutionTeacherInvitationController::class, 'revoke'])->whereNumber('invitation');
        Route::get('/schools', [InstitutionSchoolController::class, 'index']);
        Route::post('/schools', [InstitutionSchoolController::class, 'store']);
        Route::get('/schools/{school}', [InstitutionSchoolController::class, 'show'])->whereNumber('school');
        Route::patch('/schools/{school}', [InstitutionSchoolController::class, 'update'])->whereNumber('school');
        Route::delete('/schools/{school}', [InstitutionSchoolController::class, 'destroy'])->whereNumber('school');
        Route::get('/schools/{school}/participants', [InstitutionParticipantController::class, 'index'])->whereNumber('school');

        Route::prefix('/schools/{school}/academic')->whereNumber('school')->group(function () {
            Route::get('/', [InstitutionAcademicController::class, 'overview']);
            Route::post('/years', [InstitutionAcademicController::class, 'storeAcademicYear']);
            Route::post('/years/{academicYear}/terms', [InstitutionAcademicController::class, 'storeTerm'])->whereNumber('academicYear');
            Route::post('/grades', [InstitutionAcademicController::class, 'storeGrade']);
            Route::post('/sections', [InstitutionAcademicController::class, 'storeSection']);
            Route::post('/subjects', [InstitutionAcademicController::class, 'storeSubject']);
            Route::post('/teacher-assignments', [InstitutionAcademicController::class, 'assignTeacher']);
            Route::delete('/teacher-assignments/{assignment}', [InstitutionAcademicController::class, 'removeTeacherAssignment'])->whereNumber('assignment');
            Route::post('/student-enrollments', [InstitutionAcademicController::class, 'enrollStudent']);
            Route::get('/student-enrollments', [InstitutionStudentEnrollmentController::class, 'history']);
            Route::patch('/student-enrollments/{enrollment}/status', [InstitutionStudentEnrollmentController::class, 'close'])->whereNumber('enrollment');
            Route::post('/student-enrollments/{enrollment}/transfer', [InstitutionStudentEnrollmentController::class, 'transfer'])->whereNumber('enrollment');
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
            Route::get('/{entry}/available-substitutes', [InstitutionSubstitutionController::class, 'availableTeachers'])->whereNumber('entry');
            Route::post('/{entry}/substitutions', [InstitutionSubstitutionController::class, 'assign'])->whereNumber('entry');
        });

        Route::post('/schools/{school}/teacher-absences', [InstitutionSubstitutionController::class, 'reportAbsence'])->whereNumber('school');

        Route::prefix('/schools/{school}/curriculum')->whereNumber('school')->group(function () {
            Route::get('/', [InstitutionCurriculumController::class, 'overview']);
            Route::post('/books', [InstitutionCurriculumController::class, 'storeBook']);
            Route::post('/books/{book}/units', [InstitutionCurriculumController::class, 'storeUnit'])->whereNumber('book');
            Route::post('/units/{unit}/lessons', [InstitutionCurriculumController::class, 'storeLesson'])->whereNumber('unit');
        });
    });

Route::prefix('/institutions/{organizationSlug}/schools/{school}/teaching')
    ->where([
        'organizationSlug' => '[a-z0-9][a-z0-9-]{1,79}',
        'school' => '[0-9]+',
    ])
    ->middleware('organization.member:owner,admin,school_admin,teacher')
    ->group(function () {
        Route::get('/lessons/{lesson}', [InstitutionCurriculumController::class, 'showLesson'])->whereNumber('lesson');
        Route::post('/lessons/{lesson}/noor-plan', [InstitutionCurriculumController::class, 'generateNoorPlan'])->whereNumber('lesson');
        Route::post('/generations/{generation}/approve', [InstitutionCurriculumController::class, 'approveGeneration'])->whereNumber('generation');
    });
