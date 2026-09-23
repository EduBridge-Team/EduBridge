<?php

use Illuminate\Support\Facades\Route;

// الدعم الفني والشكاوى (البطاقة 11)
    Route::get('/support', [\App\Http\Controllers\SupportController::class, 'index']);
    Route::post('/support', [\App\Http\Controllers\SupportController::class, 'store']);
    Route::put('/support/{id}', [\App\Http\Controllers\SupportController::class, 'update'])
        ->middleware('role:admin');
    Route::get('/support/tickets', [\App\Http\Controllers\SupportController::class, 'index'])
        ->middleware('role:admin');
    Route::put('/support/tickets/{id}/resolve', [\App\Http\Controllers\SupportController::class, 'resolve'])
        ->middleware('role:admin');

    // دراسة الحالة مع المختصين (البطاقة 7)
    Route::get('/consultations', [\App\Http\Controllers\ConsultationController::class, 'index'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::post('/consultations', [\App\Http\Controllers\ConsultationController::class, 'store'])
        ->middleware('role:parent,teacher,admin');
    Route::get('/consultations/{id}', [\App\Http\Controllers\ConsultationController::class, 'show'])
        ->middleware('role:parent,teacher,specialist,admin');
    Route::put('/consultations/{id}', [\App\Http\Controllers\ConsultationController::class, 'update'])
        ->middleware('role:specialist,admin');
    Route::post('/consultations/{id}/notes', [\App\Http\Controllers\ConsultationController::class, 'addNote'])
        ->middleware('role:specialist,admin');

    // طلبات الدعم التعليمي — ولي الأمر يرسل، ومختص الدعم يراجع ويحدد موعد المتابعة والرابط
    Route::post('/learning-support/requests', [\App\Http\Controllers\LearningSupportRequestController::class, 'store'])
        ->middleware(['role:parent', 'throttle:10,1']);
    Route::post('/learning-support/recommendations', [\App\Http\Controllers\LearningSupportRequestController::class, 'recommendToParent'])
        ->middleware(['role:specialist,admin', 'throttle:20,1']);
    Route::get('/learning-support/requests', [\App\Http\Controllers\LearningSupportRequestController::class, 'index'])
        ->middleware('role:parent,specialist,admin');
    Route::get('/learning-support/requests/child/{childId}/pending', [\App\Http\Controllers\LearningSupportRequestController::class, 'pendingForChild'])
        ->middleware(['role:parent,specialist,admin', 'child.access']);
    Route::put('/learning-support/requests/{id}/schedule', [\App\Http\Controllers\LearningSupportMeetingController::class, 'schedule'])
        ->middleware('role:specialist,admin');
    Route::put('/learning-support/requests/{id}/complete', [\App\Http\Controllers\LearningSupportMeetingController::class, 'complete'])
        ->middleware('role:specialist,admin');
    Route::put('/learning-support/requests/{id}/cancel', [\App\Http\Controllers\LearningSupportMeetingController::class, 'cancel'])
        ->middleware('role:parent,specialist,admin');

    // الأطفال
    Route::post('/children', [\App\Http\Controllers\ChildController::class, 'store'])
        ->middleware('role:parent,admin');
    Route::get('/children', [\App\Http\Controllers\ChildController::class, 'index']);
    Route::get('/children/{id}', [\App\Http\Controllers\ChildController::class, 'show'])->middleware('child.access');
    Route::put('/children/{id}', [\App\Http\Controllers\ChildController::class, 'update'])->middleware('child.access');
    Route::delete('/children/{id}', [\App\Http\Controllers\ChildController::class, 'destroy'])
        ->middleware('role:admin');
    Route::post('/children/{id}/parents', [\App\Http\Controllers\ChildRelationController::class, 'addParent'])
        ->middleware('role:admin');
    Route::post('/children/{id}/assign-teacher', [\App\Http\Controllers\ChildRelationController::class, 'assignTeacher'])
        ->middleware('role:admin');
    Route::get('/children/{id}/lessons', [\App\Http\Controllers\ChildLessonController::class, 'lessons'])->middleware('child.access');
    Route::get('/children/{id}/evaluations', [\App\Http\Controllers\EvaluationController::class, 'byChild'])->middleware('child.access');

    // اقتراحات متابعة المختصين
    Route::post('/children/{childId}/specialist-suggestions', [\App\Http\Controllers\SpecialistSuggestionController::class, 'store'])
        ->middleware(['role:teacher,specialist,admin', 'child.access']);
    Route::get('/specialist-suggestions', [\App\Http\Controllers\SpecialistSuggestionController::class, 'index'])
        ->middleware('role:specialist,admin');
    Route::put('/specialist-suggestions/{id}/accept', [\App\Http\Controllers\SpecialistSuggestionController::class, 'accept'])
        ->middleware('role:specialist,admin');
    Route::put('/specialist-suggestions/{id}/reject', [\App\Http\Controllers\SpecialistSuggestionController::class, 'reject'])
        ->middleware('role:specialist,admin');

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

    // فريق الرعاية — واجهات موحّدة + توافق مع شاشات Flutter الحالية
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

    // دراسات الحالة التعاونية
    Route::get('/case-discussions', [\App\Http\Controllers\CaseDiscussionController::class, 'index'])
        ->middleware('role:teacher,specialist,admin');
    Route::post('/case-discussions', [\App\Http\Controllers\CaseDiscussionController::class, 'store'])
        ->middleware('role:teacher,specialist,admin');
    Route::get('/case-discussions/{id}', [\App\Http\Controllers\CaseDiscussionController::class, 'show'])
        ->middleware('role:teacher,specialist,admin');
    Route::post('/case-discussions/{id}/messages', [\App\Http\Controllers\CaseDiscussionController::class, 'addMessage'])
        ->middleware('role:teacher,specialist,admin');
    Route::put('/case-discussions/{id}/resolve', [\App\Http\Controllers\CaseDiscussionController::class, 'resolve'])
        ->middleware('role:teacher,specialist,admin');
