<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class StudentHomeworkSubmitController extends Controller
{
    public function store(Request $request, int $homework)
    {
        // Resolve the child exclusively from the authenticated school-student identity.
        // Never trust a child_id from the incoming request.
        $profile = app(StudentSelfController::class)->show($request);
        if ($profile->getStatusCode() !== 200) return $profile;

        $request->merge(['child_id' => $profile->getData(true)['student']['child_id']]);
        return app(HomeworkController::class)->submit($request, $homework);
    }
}
