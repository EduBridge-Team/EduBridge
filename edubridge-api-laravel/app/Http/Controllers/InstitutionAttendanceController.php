<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class InstitutionAttendanceController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $date = $request->query('date');
        $query = DB::table('attendance_sessions as a')
            ->join('sections as s', 's.id', '=', 'a.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->leftJoin('subjects as sub', 'sub.id', '=', 'a.subject_id')
            ->where('g.school_id', $school)
            ->select('a.*', 's.name as section_name', 'g.name as grade_name', 'sub.name as subject_name')
            ->orderByDesc('a.attendance_date')
            ->orderBy('a.period_number');

        if ($date) {
            $query->where('a.attendance_date', $date);
        }

        return response()->json(['attendance_sessions' => $query->limit(200)->get()]);
    }

    public function store(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $data = $request->validate([
            'section_id' => ['required', 'integer'],
            'subject_id' => ['nullable', 'integer'],
            'teacher_id' => ['nullable', 'integer', 'exists:users,id'],
            'attendance_date' => ['required', 'date'],
            'period_number' => ['nullable', 'integer', 'min:1', 'max:20'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if (!$this->sectionWithinSchool($school, (int) $data['section_id'])) {
            return response()->json(['error' => 'الشعبة لا تتبع هذه المدرسة'], 422);
        }

        if (!empty($data['subject_id']) && !$this->subjectWithinSchool($school, (int) $data['subject_id'])) {
            return response()->json(['error' => 'المادة لا تتبع هذه المدرسة'], 422);
        }

        $duplicate = DB::table('attendance_sessions')
            ->where('section_id', $data['section_id'])
            ->where('attendance_date', $data['attendance_date'])
            ->where('period_number', $data['period_number'] ?? null)
            ->exists();

        if ($duplicate) {
            return response()->json(['error' => 'جلسة الحضور لهذه الحصة موجودة مسبقاً'], 409);
        }

        $id = DB::table('attendance_sessions')->insertGetId([
            'section_id' => $data['section_id'],
            'subject_id' => $data['subject_id'] ?? null,
            'teacher_id' => $data['teacher_id'] ?? null,
            'attendance_date' => $data['attendance_date'],
            'period_number' => $data['period_number'] ?? null,
            'status' => 'open',
            'notes' => $data['notes'] ?? null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $students = DB::table('student_enrollments')
            ->where('section_id', $data['section_id'])
            ->where('status', 'active')
            ->pluck('child_id');

        if ($students->isNotEmpty()) {
            $rows = $students->map(fn ($childId) => [
                'attendance_session_id' => $id,
                'child_id' => $childId,
                'status' => 'present',
                'created_at' => now(),
                'updated_at' => now(),
            ])->all();
            DB::table('attendance_records')->insert($rows);
        }

        return response()->json([
            'attendance_session' => DB::table('attendance_sessions')->find($id),
            'students_initialized' => $students->count(),
        ], 201);
    }

    public function show(Request $request, string $organizationSlug, int $school, int $attendanceSession): JsonResponse
    {
        $session = $this->sessionWithinSchool($school, $attendanceSession);
        if (!$this->schoolWithinTenant($request, $school) || !$session) {
            return response()->json(['error' => 'جلسة الحضور غير موجودة'], 404);
        }

        $records = DB::table('attendance_records as r')
            ->join('children as c', 'c.id', '=', 'r.child_id')
            ->where('r.attendance_session_id', $attendanceSession)
            ->select('r.*', 'c.name as child_name')
            ->orderBy('c.name')
            ->get();

        return response()->json(['attendance_session' => $session, 'records' => $records]);
    }

    public function mark(Request $request, string $organizationSlug, int $school, int $attendanceSession): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school) || !$this->sessionWithinSchool($school, $attendanceSession)) {
            return response()->json(['error' => 'جلسة الحضور غير موجودة'], 404);
        }

        $data = $request->validate([
            'records' => ['required', 'array', 'min:1', 'max:500'],
            'records.*.child_id' => ['required', 'integer'],
            'records.*.status' => ['required', Rule::in(['present', 'absent', 'late', 'excused'])],
            'records.*.note' => ['nullable', 'string', 'max:1000'],
            'close_session' => ['nullable', 'boolean'],
        ]);

        $actor = $request->attributes->get('jwt_user');
        $validChildren = DB::table('student_enrollments')
            ->where('section_id', $this->sessionWithinSchool($school, $attendanceSession)->section_id)
            ->where('status', 'active')
            ->pluck('child_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        foreach ($data['records'] as $record) {
            if (!in_array((int) $record['child_id'], $validChildren, true)) {
                return response()->json(['error' => 'أحد الطلاب لا يتبع الشعبة الحالية'], 422);
            }
        }

        DB::transaction(function () use ($data, $attendanceSession, $actor) {
            foreach ($data['records'] as $record) {
                DB::table('attendance_records')->updateOrInsert(
                    ['attendance_session_id' => $attendanceSession, 'child_id' => $record['child_id']],
                    [
                        'status' => $record['status'],
                        'note' => $record['note'] ?? null,
                        'marked_by' => $actor->id ?? null,
                        'marked_at' => now(),
                        'updated_at' => now(),
                        'created_at' => now(),
                    ]
                );
            }

            if ($data['close_session'] ?? false) {
                DB::table('attendance_sessions')->where('id', $attendanceSession)->update(['status' => 'closed', 'updated_at' => now()]);
            }
        });

        return response()->json(['message' => 'تم حفظ الحضور بنجاح']);
    }

    private function schoolWithinTenant(Request $request, int $school): ?object
    {
        $organization = $request->attributes->get('organization');
        return DB::table('schools')->where('id', $school)->where('organization_id', $organization->id)->first();
    }

    private function sectionWithinSchool(int $school, int $section): bool
    {
        return DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')->where('s.id', $section)->where('g.school_id', $school)->exists();
    }

    private function subjectWithinSchool(int $school, int $subject): bool
    {
        return DB::table('subjects')->where('id', $subject)->where('school_id', $school)->exists();
    }

    private function sessionWithinSchool(int $school, int $session): ?object
    {
        return DB::table('attendance_sessions as a')
            ->join('sections as s', 's.id', '=', 'a.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('a.id', $session)
            ->where('g.school_id', $school)
            ->select('a.*')
            ->first();
    }
}
