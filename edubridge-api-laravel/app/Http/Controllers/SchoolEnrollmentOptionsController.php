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

        $query = ($actor->role ?? null) === 'school'
            ? DB::table('school_accounts as account')->join('schools as school', 'school.id', '=', 'account.school_id')
            : DB::table('school_management_assignments as account')
                ->join('schools as school', 'school.id', '=', 'account.school_id')
                ->where('account.role', 'director')->whereNull('account.ends_at');
        $schools = $query
            ->leftJoin('organizations as organization', 'organization.id', '=', 'school.organization_id')
            ->where('account.user_id', $actor->id)->where('school.is_active', true)
            ->where(function ($query) {
                $query->whereNull('school.organization_id')->orWhere('organization.is_active', true);
            })->select('school.id')->limit(2)->get();
        if ($schools->count() !== 1) {
            return response()->json(['error' => 'School access unavailable'], 403);
        }
        $school = $schools->first();

        // A school account only sees current sections owned by its own school.
        // The decision endpoint must independently validate eligibility and capacity.
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
