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

    public function report(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'section_id' => ['nullable', 'integer'],
        ]);

        if (!empty($data['section_id']) && !$this->sectionWithinSchool($school, (int) $data['section_id'])) {
            return response()->json(['error' => 'الشعبة لا تتبع هذه المدرسة'], 422);
        }

        $base = DB::table('attendance_records as r')
            ->join('attendance_sessions as a', 'a.id', '=', 'r.attendance_session_id')
            ->join('sections as s', 's.id', '=', 'a.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('g.school_id', $school);

        if (!empty($data['from'])) {
            $base->whereDate('a.attendance_date', '>=', $data['from']);
        }
        if (!empty($data['to'])) {
            $base->whereDate('a.attendance_date', '<=', $data['to']);
        }
        if (!empty($data['section_id'])) {
            $base->where('a.section_id', $data['section_id']);
        }

        $summary = (clone $base)
            ->select('r.status', DB::raw('COUNT(*) as total'))
            ->groupBy('r.status')
            ->pluck('total', 'status');

        $students = (clone $base)
            ->join('children as c', 'c.id', '=', 'r.child_id')
            ->select(
                'c.id as child_id',
                'c.name as child_name',
                DB::raw("COUNT(*) as total_sessions"),
                DB::raw("SUM(CASE WHEN r.status = 'present' THEN 1 ELSE 0 END) as present_count"),
                DB::raw("SUM(CASE WHEN r.status = 'absent' THEN 1 ELSE 0 END) as absent_count"),
                DB::raw("SUM(CASE WHEN r.status = 'late' THEN 1 ELSE 0 END) as late_count"),
                DB::raw("SUM(CASE WHEN r.status = 'excused' THEN 1 ELSE 0 END) as excused_count")
            )
            ->groupBy('c.id', 'c.name')
            ->orderBy('c.name')
            ->get()
            ->map(function ($row) {
                $row->attendance_rate = (int) $row->total_sessions > 0
                    ? round(((int) $row->present_count / (int) $row->total_sessions) * 100, 1)
                    : 0;
                return $row;
            });

        return response()->json([
            'summary' => [
                'present' => (int) ($summary['present'] ?? 0),
                'absent' => (int) ($summary['absent'] ?? 0),
                'late' => (int) ($summary['late'] ?? 0),
                'excused' => (int) ($summary['excused'] ?? 0),
            ],
            'students' => $students,
        ]);
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

        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

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
        $session = $this->sessionWithinSchool($school, $attendanceSession);
        if ($session->status === 'closed') {
            return response()->json(['error' => 'سجل الحضور مغلق ولا يمكن تعديله'], 409);
        }
        $validChildren = DB::table('student_enrollments')
            ->where('section_id', $session->section_id)
            ->where('status', 'active')
            ->pluck('child_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        foreach ($data['records'] as $record) {
            if (!in_array((int) $record['child_id'], $validChildren, true)) {
                return response()->json(['error' => 'أحد الطلاب لا يتبع الشعبة الحالية'], 422);
            }
        }

        DB::transaction(function () use ($data, $attendanceSession, $actor, $session) {
            foreach ($data['records'] as $record) {
                $previous = DB::table('attendance_records')
                    ->where('attendance_session_id', $attendanceSession)
                    ->where('child_id', $record['child_id'])
                    ->value('status');

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

                if (in_array($record['status'], ['absent', 'late'], true) && $previous !== $record['status']) {
                    $this->notifyParents((int) $record['child_id'], $record['status'], $session);
                }
            }

            if ($data['close_session'] ?? false) {
                DB::table('attendance_sessions')->where('id', $attendanceSession)->update(['status' => 'closed', 'updated_at' => now()]);
            }
        });

        return response()->json(['message' => 'تم حفظ الحضور بنجاح']);
    }

    private function notifyParents(int $childId, string $status, object $session): void
    {
        $childName = DB::table('children')->where('id', $childId)->value('name') ?? 'الطالب';
        $parents = DB::table('child_parent')->where('child_id', $childId)->pluck('parent_id');
        $label = $status === 'absent' ? 'غياب' : 'تأخر';
        $message = "تم تسجيل {$label} {$childName} بتاريخ {$session->attendance_date}"
            . ($session->period_number ? " في الحصة {$session->period_number}" : '');

        foreach ($parents as $parentId) {
            $exists = DB::table('notifications')
                ->where('user_id', $parentId)
                ->where('type', 'school_attendance')
                ->where('message', $message)
                ->exists();

            if (!$exists) {
                DB::table('notifications')->insert([
                    'user_id' => $parentId,
                    'title' => "تنبيه {$label}",
                    'message' => $message,
                    'type' => 'school_attendance',
                    'is_read' => false,
                    'created_at' => now(),
                ]);
            }
        }
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
