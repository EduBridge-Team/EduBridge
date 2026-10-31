<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolCurriculumCatalogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'Forbidden'], 403);
        }

        $school = \App\Support\SchoolScopedAccess::resolve($request, 'academic');
        if (!$school) return response()->json(['error' => 'School access unavailable'], 403);
        $schoolId = (int) $school->id;
        $years = DB::table('academic_years')->where('school_id', $schoolId)
            ->orderByDesc('starts_on')->get(['id', 'school_id', 'name', 'starts_on', 'ends_on', 'is_current'])
            ->map(fn ($year) => [
                'id' => (int) $year->id, 'school_id' => (int) $year->school_id,
                'name' => $year->name,
                'starts_on' => (string) $year->starts_on,
                'ends_on' => (string) $year->ends_on,
                'is_current' => (bool) $year->is_current,
            ])->values();
        $terms = DB::table('academic_terms as term')
            ->join('academic_years as year', 'year.id', '=', 'term.academic_year_id')
            ->where('year.school_id', $schoolId)
            ->orderBy('term.academic_year_id')->orderBy('term.position')
            ->get(['term.id', 'year.school_id', 'term.academic_year_id',
                'term.name', 'term.position', 'term.starts_on', 'term.ends_on'])
            ->map(fn ($term) => [
                'id' => (int) $term->id, 'school_id' => (int) $term->school_id,
                'academic_year_id' => (int) $term->academic_year_id,
                'name' => $term->name, 'position' => (int) $term->position,
                'starts_on' => (string) $term->starts_on,
                'ends_on' => (string) $term->ends_on,
            ])->values();
        $subjects = DB::table('subjects')->where('school_id', $schoolId)
            ->orderBy('name')->get(['id', 'school_id', 'name', 'code', 'is_active'])
            ->map(fn ($subject) => [
                'id' => (int) $subject->id, 'school_id' => (int) $subject->school_id,
                'name' => $subject->name, 'code' => $subject->code,
                'is_active' => (bool) $subject->is_active,
            ])->values();

        return response()->json([
            'school' => ['id' => $schoolId, 'name' => $school->name],
            'academic_years' => $years,
            'academic_terms' => $terms,
            'subjects' => $subjects,
        ]);
    }
}
