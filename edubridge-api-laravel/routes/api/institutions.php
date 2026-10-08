<?php

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
    });
