<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InstitutionParticipantController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $organization = $request->attributes->get('organization');

        $schoolExists = DB::table('schools')
            ->where('id', $school)
            ->where('organization_id', $organization->id)
            ->exists();

        if (!$schoolExists) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $teachers = DB::table('organization_user as ou')
            ->join('users as u', 'u.id', '=', 'ou.user_id')
            ->where('ou.organization_id', $organization->id)
            ->where('ou.is_active', true)
            ->where('ou.role', 'teacher')
            ->select('u.id', 'u.name', 'u.email')
            ->orderBy('u.name')
            ->get();

        $students = DB::table('children as c')
            ->where('c.organization_id', $organization->id)
            ->select('c.id', 'c.name', 'c.status')
            ->orderBy('c.name')
            ->get();

        $teacherAssignments = DB::table('teacher_assignments as ta')
            ->join('sections as s', 's.id', '=', 'ta.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('subjects as sub', 'sub.id', '=', 'ta.subject_id')
            ->join('users as u', 'u.id', '=', 'ta.teacher_id')
            ->where('g.school_id', $school)
            ->where('sub.school_id', $school)
            ->select(
                'ta.id',
                'ta.section_id',
                'ta.subject_id',
                'ta.teacher_id',
                's.name as section_name',
                'g.name as grade_name',
                'sub.name as subject_name',
                'u.name as teacher_name'
            )
            ->orderBy('g.position')
            ->orderBy('s.name')
            ->orderBy('sub.name')
            ->get();

        $studentEnrollments = DB::table('student_enrollments as se')
            ->join('sections as s', 's.id', '=', 'se.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('children as c', 'c.id', '=', 'se.child_id')
            ->where('g.school_id', $school)
            ->where('se.status', 'active')
            ->where('c.organization_id', $organization->id)
            ->select(
                'se.id',
                'se.section_id',
                'se.child_id',
                'se.enrolled_on',
                's.name as section_name',
                'g.name as grade_name',
                'c.name as child_name'
            )
            ->orderBy('g.position')
            ->orderBy('s.name')
            ->orderBy('c.name')
            ->get();

        return response()->json([
            'teachers' => $teachers,
            'students' => $students,
            'teacher_assignments' => $teacherAssignments,
            'student_enrollments' => $studentEnrollments,
        ]);
    }
}
