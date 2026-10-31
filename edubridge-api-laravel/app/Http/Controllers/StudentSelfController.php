<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentSelfController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || ($actor->role ?? null) !== 'student') {
            return response()->json(['error' => 'Student access required'], 403);
        }

        $student = DB::table('student_account_links as link')
            ->join('school_internal_identities as identity', function ($join) {
                $join->on('identity.user_id', '=', 'link.user_id')
                    ->on('identity.school_id', '=', 'link.school_id');
            })
            ->join('schools as school', 'school.id', '=', 'link.school_id')
            ->join('children as child', 'child.id', '=', 'link.child_id')
            ->join('student_enrollments as enrollment', 'enrollment.child_id', '=', 'child.id')
            ->join('sections as section', 'section.id', '=', 'enrollment.section_id')
            ->join('grades as grade', 'grade.id', '=', 'section.grade_id')
            ->where('link.user_id', $actor->id)
            ->where('grade.school_id', '=', DB::raw('link.school_id'))
            ->where('enrollment.status', 'active')
            ->where('school.is_active', true)
            ->where('identity.is_active', true)
            ->select('child.id as child_id', 'child.name as child_name',
                'school.id as school_id', 'section.id as section_id',
                'grade.id as grade_id')
            ->limit(2)->get();

        if ($student->count() !== 1) {
            return response()->json(['error' => 'Student enrollment unavailable'], 403);
        }
        return response()->json(['student' => $student->first()]);
    }
    public function timetable(Request $request): JsonResponse
    {
        $profile = $this->show($request);
        if ($profile->getStatusCode() !== 200) return $profile;
        $student = $profile->getData(true)['student'];

        $entries = DB::table('timetable_entries as entry')
            ->join('subjects as subject', 'subject.id', '=', 'entry.subject_id')
            ->leftJoin('users as teacher', 'teacher.id', '=', 'entry.teacher_id')
            ->where('entry.school_id', $student['school_id'])
            ->where('entry.section_id', $student['section_id'])
            ->select('entry.weekday', 'entry.period_number', 'entry.starts_at', 'entry.ends_at',
                'subject.name as subject_name', 'teacher.name as teacher_name')
            ->orderBy('entry.weekday')->orderBy('entry.period_number')->get();

        return response()->json(['timetable' => $entries]);
    }

}
