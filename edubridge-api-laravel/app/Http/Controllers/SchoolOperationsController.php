<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolOperationsController extends Controller
{
    // Only these existing, school-scoped operations can be delegated.
    private const ACTIONS = [
        'academic' => ['context', 'GET', InstitutionAcademicController::class, 'overview'],
        'years' => ['academic', 'POST', InstitutionAcademicController::class, 'storeAcademicYear'],
        'terms' => ['academic', 'POST', InstitutionAcademicController::class, 'storeTerm', 'academic_year_id'],
        'grades' => ['academic', 'POST', InstitutionAcademicController::class, 'storeGrade'],
        'sections' => ['academic', 'POST', InstitutionAcademicController::class, 'storeSection'],
        'subjects' => ['academic', 'POST', InstitutionAcademicController::class, 'storeSubject'],
        'teachers' => ['context', 'GET', self::class, 'teachers'],
        'participants' => ['academic', 'GET', InstitutionParticipantController::class, 'index'],
        'assign-teacher' => ['academic', 'POST', InstitutionAcademicController::class, 'assignTeacher'],
        'remove-teacher' => ['academic', 'DELETE', InstitutionAcademicController::class, 'removeTeacherAssignment', 'assignment_id'],
        'students' => ['enrollment', 'GET', InstitutionStudentEnrollmentController::class, 'history'],
        'student-status' => ['enrollment', 'PATCH', InstitutionStudentEnrollmentController::class, 'close', 'enrollment_id'],
        'student-transfer' => ['enrollment', 'POST', InstitutionStudentEnrollmentController::class, 'transfer', 'enrollment_id'],
        'promotion-preview' => ['enrollment', 'POST', JabaliaBulkPromotionController::class, 'preview'],
        'promotion-approve' => ['enrollment', 'POST', JabaliaBulkPromotionController::class, 'approve'],
        'staff-attendance' => ['attendance', 'GET', SchoolStaffAttendanceController::class, 'index'],
        'staff-attendance-mark' => ['attendance', 'PUT', SchoolStaffAttendanceController::class, 'mark'],
        'attendance' => ['attendance', 'GET', InstitutionAttendanceController::class, 'index'],
        'attendance-create' => ['attendance', 'POST', InstitutionAttendanceController::class, 'store'],
        'attendance-session' => ['attendance', 'GET', InstitutionAttendanceController::class, 'show', 'session_id'],
        'attendance-mark' => ['attendance', 'PUT', InstitutionAttendanceController::class, 'mark', 'session_id'],
        'attendance-report' => ['attendance', 'GET', InstitutionAttendanceController::class, 'report'],
        'timetable' => ['timetable', 'GET', InstitutionTimetableController::class, 'index'],
        'timetable-create' => ['timetable', 'POST', InstitutionTimetableController::class, 'store'],
        'timetable-settings' => ['timetable', 'GET', JabaliaTimetableSettingsController::class, 'show'],
        'timetable-settings-update' => ['timetable', 'PUT', JabaliaTimetableSettingsController::class, 'update'],
        'subject-quotas' => ['timetable', 'GET', JabaliaSubjectQuotaController::class, 'index'],
        'subject-quotas-update' => ['timetable', 'PUT', JabaliaSubjectQuotaController::class, 'update'],
        'timetable-delete' => ['timetable', 'DELETE', InstitutionTimetableController::class, 'destroy', 'entry_id'],
        'reports' => ['reports', 'GET', self::class, 'report'],
        'curriculum' => ['curriculum', 'GET', InstitutionCurriculumController::class, 'overview'],
        'books' => ['curriculum', 'POST', InstitutionCurriculumController::class, 'storeBook'],
        'units' => ['curriculum', 'POST', InstitutionCurriculumController::class, 'storeUnit', 'book_id'],
        'lessons' => ['curriculum', 'POST', InstitutionCurriculumController::class, 'storeLesson', 'unit_id'],
    ];

    public function handle(Request $request, string $action): JsonResponse
    {
        $definition = self::ACTIONS[$action] ?? null;
        if (!$definition) return response()->json(['error' => 'Operation unavailable'], 404);
        [$permission, $method, $controller, $handler] = $definition;
        if ($request->method() !== $method) return response()->json(['error' => 'Method not allowed'], 405);
        $school = SchoolScopedAccess::resolve($request, $permission);
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        if ($method !== 'GET') $request->validate(['expected_school_id' => ['required', 'integer', 'in:'.$school->id]]);
        $organization = $school->organization_id === null ? (object) ['id' => null, 'slug' => null]
            : DB::table('organizations')->where('id', $school->organization_id)->first();
        $request->attributes->set('organization', $organization);
        $request->attributes->set('managed_school', (int) $school->id);
        $arguments = [$request, (string) ($organization->slug ?? ''), (int) $school->id];
        if (isset($definition[4])) {
            $value = $request->validate([$definition[4] => ['required', 'integer', 'min:1']]);
            $arguments[] = (int) $value[$definition[4]];
        }
        $response = app($controller)->{$handler}(...$arguments);
        if ($response->getStatusCode() >= 200 && $response->getStatusCode() < 300) {
            $response->setData([...$response->getData(true), 'school_id' => (int) $school->id]);
        }
        return $response;
    }

    public function report(Request $request, string $slug, int $school): JsonResponse
    {
        // This method is reached through the allowlisted dispatcher after scope resolution.
        if ((int) $request->attributes->get('managed_school') !== $school) return response()->json(['error' => 'Forbidden'], 403);
        $students = DB::table('student_enrollments as e')->join('sections as s', 's.id', '=', 'e.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')->where('g.school_id', $school)->where('e.status', 'active')->distinct()->count('e.child_id');
        $teachers = DB::table('teacher_assignments as a')->join('sections as s', 's.id', '=', 'a.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')->where('g.school_id', $school)->distinct()->count('a.teacher_id');
        return response()->json(['statistics' => ['students' => $students, 'teachers' => $teachers,
            'grades' => DB::table('grades')->where('school_id', $school)->count(),
            'lessons' => DB::table('timetable_entries')->where('school_id', $school)->count(),
            'books' => DB::table('curriculum_books')->where('school_id', $school)->count()]]);
    }

    public function teachers(Request $request, string $slug, int $school): JsonResponse
    {
        if ((int) $request->attributes->get('managed_school') !== $school) return response()->json(['error' => 'Forbidden'], 403);
        $teachers = DB::table('users as u')->where('u.role', 'teacher')->where(function ($q) use ($school) {
            $q->whereIn('u.id', DB::table('school_internal_identities')->where('school_id', $school)->where('is_active', true)->select('user_id'))
                ->orWhereIn('u.id', DB::table('teacher_assignments as a')->join('sections as s', 's.id', '=', 'a.section_id')
                    ->join('grades as g', 'g.id', '=', 's.grade_id')->where('g.school_id', $school)->select('a.teacher_id'));
        })->get(['u.id', 'u.name']);
        return response()->json(['teachers' => $teachers]);
    }
}
