<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolEnrollmentOptionsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'Forbidden'], 403);
        }

        $school = \App\Support\SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school) return response()->json(['error' => 'School access unavailable'], 403);
        $sections = DB::table('sections as section')
            ->join('grades as grade', 'grade.id', '=', 'section.grade_id')
            ->join('academic_years as year', 'year.id', '=', 'section.academic_year_id')
            ->where('grade.school_id', $school->id)
            ->where('year.school_id', $school->id)
            ->where('year.is_current', true)
            ->where('grade.is_active', true)
            ->select(
                'section.id',
                'section.name',
                'grade.name as grade_name',
                'year.id as academic_year_id',
                'year.name as academic_year_name'
            )
            ->orderBy('grade.position')
            ->orderBy('section.name')
            ->get();

        return response()->json([
            'school_id' => (int) $school->id,
            'sections' => $sections,
        ]);
    }
}
