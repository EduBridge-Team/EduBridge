<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class InstitutionTimetableController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $query = DB::table('timetable_entries as t')
            ->join('sections as s', 's.id', '=', 't.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('subjects as sub', 'sub.id', '=', 't.subject_id')
            ->leftJoin('users as u', 'u.id', '=', 't.teacher_id')
            ->where('t.school_id', $school)
            ->select('t.*', 's.name as section_name', 'g.name as grade_name', 'sub.name as subject_name', 'u.name as teacher_name')
            ->orderBy('t.weekday')->orderBy('t.period_number');

        if ($request->filled('weekday')) {
            $query->where('t.weekday', (int) $request->query('weekday'));
        }

        return response()->json(['timetable' => $query->get()]);
    }

    public function store(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'academic_year_id' => ['required', 'integer'],
            'section_id' => ['required', 'integer'],
            'subject_id' => ['required', 'integer'],
            'teacher_id' => ['nullable', 'integer', 'exists:users,id'],
            'weekday' => ['required', 'integer', 'min:1', 'max:7'],
            'period_number' => ['required', 'integer', 'min:1', 'max:20'],
            'starts_at' => ['nullable', 'date_format:H:i'],
            'ends_at' => ['nullable', 'date_format:H:i', 'after:starts_at'],
            'room' => ['nullable', 'string', 'max:80'],
        ]);

        if (!$this->academicYearWithinSchool($school, (int) $data['academic_year_id'])
            || !$this->sectionWithinSchool($school, (int) $data['section_id'])
            || !$this->subjectWithinSchool($school, (int) $data['subject_id'])) {
            return response()->json(['error' => 'بيانات الجدول لا تتبع هذه المدرسة'], 422);
        }

        $sectionYear = DB::table('sections')->where('id', $data['section_id'])->value('academic_year_id');
        if ((int) $sectionYear !== (int) $data['academic_year_id']) {
            return response()->json(['error' => 'الشعبة لا تتبع السنة الدراسية المحددة'], 422);
        }

        if (!empty($data['teacher_id']) && !$this->teacherWithinOrganization($request, (int) $data['teacher_id'])) {
            return response()->json(['error' => 'المعلم لا يتبع هذه المؤسسة'], 422);
        }

        $conflict = DB::table('timetable_entries')
            ->where('school_id', $school)
            ->where('academic_year_id', $data['academic_year_id'])
            ->where('weekday', $data['weekday'])
            ->where('period_number', $data['period_number'])
            ->where(function ($query) use ($data) {
                $query->where('section_id', $data['section_id']);
                if (!empty($data['teacher_id'])) {
                    $query->orWhere('teacher_id', $data['teacher_id']);
                }
                if (!empty($data['room'])) {
                    $query->orWhere('room', $data['room']);
                }
            })
            ->first();

        if ($conflict) {
            return response()->json([
                'error' => 'يوجد تعارض في الجدول لهذه الحصة',
                'conflict_entry_id' => $conflict->id,
            ], 409);
        }

        $id = DB::table('timetable_entries')->insertGetId([
            'school_id' => $school,
            'academic_year_id' => $data['academic_year_id'],
            'section_id' => $data['section_id'],
            'subject_id' => $data['subject_id'],
            'teacher_id' => $data['teacher_id'] ?? null,
            'weekday' => $data['weekday'],
            'period_number' => $data['period_number'],
            'starts_at' => $data['starts_at'] ?? null,
            'ends_at' => $data['ends_at'] ?? null,
            'room' => $data['room'] ?? null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['timetable_entry' => DB::table('timetable_entries')->find($id)], 201);
    }

    public function destroy(Request $request, string $organizationSlug, int $school, int $entry): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $deleted = DB::table('timetable_entries')->where('id', $entry)->where('school_id', $school)->delete();
        return $deleted
            ? response()->json(['message' => 'تم حذف الحصة من الجدول'])
            : response()->json(['error' => 'الحصة غير موجودة'], 404);
    }

    private function schoolWithinTenant(Request $request, int $school): ?object
    {
        $organization = $request->attributes->get('organization');
        return DB::table('schools')->where('id', $school)->where('organization_id', $organization->id)->first();
    }

    private function academicYearWithinSchool(int $school, int $id): bool
    {
        return DB::table('academic_years')->where('id', $id)->where('school_id', $school)->exists();
    }

    private function sectionWithinSchool(int $school, int $id): bool
    {
        return DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')->where('s.id', $id)->where('g.school_id', $school)->exists();
    }

    private function subjectWithinSchool(int $school, int $id): bool
    {
        return DB::table('subjects')->where('id', $id)->where('school_id', $school)->exists();
    }

    private function teacherWithinOrganization(Request $request, int $teacher): bool
    {
        $organization = $request->attributes->get('organization');
        return DB::table('organization_user')
            ->where('organization_id', $organization->id)
            ->where('user_id', $teacher)
            ->where('is_active', true)
            ->whereIn('role', ['teacher', 'owner', 'admin', 'school_admin'])
            ->exists();
    }
}
