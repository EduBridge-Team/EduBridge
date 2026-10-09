<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InstitutionManagementReportController extends Controller
{
    public function index(Request $request, string $organizationSlug): JsonResponse
    {
        $filters = $request->validate(['from' => ['nullable', 'date'], 'to' => ['nullable', 'date', 'after_or_equal:from']]);
        $organization = $request->attributes->get('organization');
        $schools = DB::table('schools')->where('organization_id', $organization->id)
            ->select('id', 'name')->orderBy('name')->get();

        $activeTeachers = DB::table('organization_user')
            ->where('organization_id', $organization->id)->where('role', 'teacher')
            ->where('is_active', true)->count();

        $students = DB::table('children')->where('organization_id', $organization->id)->count();

        $results = $schools->map(function ($school) use ($organization, $filters) {
            $sectionIds = DB::table('sections as s')
                ->join('grades as g', 'g.id', '=', 's.grade_id')
                ->where('g.school_id', $school->id)->pluck('s.id');

            $activeEnrollments = DB::table('student_enrollments as e')
                ->join('children as c', 'c.id', '=', 'e.child_id')
                ->whereIn('e.section_id', $sectionIds)
                ->where('c.organization_id', $organization->id)
                ->where('e.status', 'active')->count();

            $sessions = DB::table('attendance_sessions')
                ->whereIn('section_id', $sectionIds);
            if (!empty($filters['from'])) $sessions->whereDate('attendance_date', '>=', $filters['from']);
            if (!empty($filters['to'])) $sessions->whereDate('attendance_date', '<=', $filters['to']);
            $sessionCount = (clone $sessions)->count();

            $attendance = DB::table('attendance_records as r')
                ->join('attendance_sessions as a', 'a.id', '=', 'r.attendance_session_id')
                ->join('children as c', 'c.id', '=', 'r.child_id')
                ->whereIn('a.section_id', $sectionIds)
                ->where('c.organization_id', $organization->id)
                ->select('r.status', DB::raw('COUNT(*) as total'))
                ->when(!empty($filters['from']), fn ($q) => $q->whereDate('a.attendance_date', '>=', $filters['from']))
                ->when(!empty($filters['to']), fn ($q) => $q->whereDate('a.attendance_date', '<=', $filters['to']))
                ->groupBy('r.status')->pluck('total', 'status');

            return [
                'school_id' => $school->id,
                'school_name' => $school->name,
                'sections' => $sectionIds->count(),
                'active_enrollments' => $activeEnrollments,
                'timetable_entries' => DB::table('timetable_entries')->where('school_id', $school->id)->count(),
                'attendance_sessions' => $sessionCount,
                'attendance' => [
                    'present' => (int) ($attendance['present'] ?? 0),
                    'absent' => (int) ($attendance['absent'] ?? 0),
                    'late' => (int) ($attendance['late'] ?? 0),
                    'excused' => (int) ($attendance['excused'] ?? 0),
                ],
            ];
        });

        return response()->json([
            'summary' => [
                'schools' => $schools->count(),
                'active_teachers' => $activeTeachers,
                'student_files' => $students,
                'active_enrollments' => $results->sum('active_enrollments'),
                'attendance_sessions' => $results->sum('attendance_sessions'),
            ],
            'schools' => $results,
        ]);
    }
}
