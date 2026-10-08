<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class InstitutionAcademicController extends Controller
{
    public function overview(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $schoolRecord = $this->schoolWithinTenant($request, $school);
        if (!$schoolRecord) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $years = DB::table('academic_years')->where('school_id', $school)->orderByDesc('starts_on')->get();
        $grades = DB::table('grades')->where('school_id', $school)->orderBy('position')->orderBy('name')->get();
        $subjects = DB::table('subjects')->where('school_id', $school)->orderBy('name')->get();

        return response()->json([
            'school' => $schoolRecord,
            'academic_years' => $years,
            'grades' => $grades,
            'subjects' => $subjects,
        ]);
    }

    public function storeAcademicYear(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:40', Rule::unique('academic_years', 'name')->where(fn ($q) => $q->where('school_id', $school))],
            'starts_on' => ['required', 'date'],
            'ends_on' => ['required', 'date', 'after:starts_on'],
            'is_current' => ['nullable', 'boolean'],
        ]);

        return DB::transaction(function () use ($data, $school) {
            if ($data['is_current'] ?? false) {
                DB::table('academic_years')->where('school_id', $school)->update(['is_current' => false, 'updated_at' => now()]);
            }

            $id = DB::table('academic_years')->insertGetId([
                'school_id' => $school,
                'name' => $data['name'],
                'starts_on' => $data['starts_on'],
                'ends_on' => $data['ends_on'],
                'is_current' => $data['is_current'] ?? false,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return response()->json(['academic_year' => DB::table('academic_years')->find($id)], 201);
        });
    }

    public function storeTerm(Request $request, string $organizationSlug, int $school, int $academicYear): JsonResponse
    {
        $year = $this->academicYearWithinTenant($request, $school, $academicYear);
        if (!$year) {
            return response()->json(['error' => 'السنة الدراسية غير موجودة'], 404);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:60'],
            'position' => ['required', 'integer', 'min:1', 'max:20', Rule::unique('academic_terms', 'position')->where(fn ($q) => $q->where('academic_year_id', $academicYear))],
            'starts_on' => ['required', 'date', 'after_or_equal:'.$year->starts_on],
            'ends_on' => ['required', 'date', 'after:starts_on', 'before_or_equal:'.$year->ends_on],
        ]);

        $id = DB::table('academic_terms')->insertGetId([
            'academic_year_id' => $academicYear,
            ...$data,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['term' => DB::table('academic_terms')->find($id)], 201);
    }

    public function storeGrade(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:80', Rule::unique('grades', 'name')->where(fn ($q) => $q->where('school_id', $school))],
            'code' => ['nullable', 'string', 'max:40'],
            'position' => ['nullable', 'integer', 'min:1', 'max:100'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $id = DB::table('grades')->insertGetId([
            'school_id' => $school,
            'name' => $data['name'],
            'code' => $data['code'] ?? null,
            'position' => $data['position'] ?? 1,
            'is_active' => $data['is_active'] ?? true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['grade' => DB::table('grades')->find($id)], 201);
    }

    public function storeSection(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $data = $request->validate([
            'grade_id' => ['required', 'integer'],
            'academic_year_id' => ['required', 'integer'],
            'name' => ['required', 'string', 'max:80'],
            'capacity' => ['nullable', 'integer', 'min:1', 'max:500'],
            'homeroom_teacher_id' => ['nullable', 'integer', 'exists:users,id'],
        ]);

        if (!$this->gradeWithinSchool($school, (int) $data['grade_id']) || !$this->academicYearWithinTenant($request, $school, (int) $data['academic_year_id'])) {
            return response()->json(['error' => 'الصف أو السنة الدراسية لا يتبعان هذه المدرسة'], 422);
        }

        $exists = DB::table('sections')->where('grade_id', $data['grade_id'])->where('academic_year_id', $data['academic_year_id'])->where('name', $data['name'])->exists();
        if ($exists) {
            return response()->json(['error' => 'الشعبة موجودة مسبقاً'], 409);
        }

        $id = DB::table('sections')->insertGetId([
            ...$data,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['section' => DB::table('sections')->find($id)], 201);
    }

    public function storeSubject(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:120', Rule::unique('subjects', 'name')->where(fn ($q) => $q->where('school_id', $school))],
            'code' => ['nullable', 'string', 'max:40'],
            'color' => ['nullable', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $id = DB::table('subjects')->insertGetId([
            'school_id' => $school,
            'name' => $data['name'],
            'code' => $data['code'] ?? null,
            'color' => $data['color'] ?? null,
            'is_active' => $data['is_active'] ?? true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['subject' => DB::table('subjects')->find($id)], 201);
    }

    public function assignTeacher(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $data = $request->validate([
            'section_id' => ['required', 'integer'],
            'subject_id' => ['required', 'integer'],
            'teacher_id' => ['required', 'integer', 'exists:users,id'],
        ]);

        if (!$this->sectionWithinSchool($school, (int) $data['section_id']) || !$this->subjectWithinSchool($school, (int) $data['subject_id'])) {
            return response()->json(['error' => 'الشعبة أو المادة لا تتبع هذه المدرسة'], 422);
        }

        $id = DB::table('teacher_assignments')->updateOrInsert(
            ['section_id' => $data['section_id'], 'subject_id' => $data['subject_id'], 'teacher_id' => $data['teacher_id']],
            ['updated_at' => now(), 'created_at' => now()]
        );

        return response()->json(['assigned' => (bool) $id], 201);
    }

    public function enrollStudent(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $organization = $request->attributes->get('organization');
        $data = $request->validate([
            'section_id' => ['required', 'integer'],
            'child_id' => ['required', 'integer', 'exists:children,id'],
            'enrolled_on' => ['nullable', 'date'],
        ]);

        if (!$this->sectionWithinSchool($school, (int) $data['section_id'])) {
            return response()->json(['error' => 'الشعبة لا تتبع هذه المدرسة'], 422);
        }

        $childBelongsToTenant = DB::table('children')->where('id', $data['child_id'])->where('organization_id', $organization->id)->exists();
        if (!$childBelongsToTenant) {
            return response()->json(['error' => 'الطالب لا يتبع هذه المؤسسة'], 422);
        }

        DB::table('student_enrollments')->updateOrInsert(
            ['section_id' => $data['section_id'], 'child_id' => $data['child_id']],
            ['status' => 'active', 'enrolled_on' => $data['enrolled_on'] ?? now()->toDateString(), 'left_on' => null, 'updated_at' => now(), 'created_at' => now()]
        );

        return response()->json(['enrolled' => true], 201);
    }

    private function schoolWithinTenant(Request $request, int $school): ?object
    {
        $organization = $request->attributes->get('organization');
        return DB::table('schools')->where('id', $school)->where('organization_id', $organization->id)->first();
    }

    private function academicYearWithinTenant(Request $request, int $school, int $academicYear): ?object
    {
        if (!$this->schoolWithinTenant($request, $school)) return null;
        return DB::table('academic_years')->where('id', $academicYear)->where('school_id', $school)->first();
    }

    private function gradeWithinSchool(int $school, int $grade): bool
    {
        return DB::table('grades')->where('id', $grade)->where('school_id', $school)->exists();
    }

    private function subjectWithinSchool(int $school, int $subject): bool
    {
        return DB::table('subjects')->where('id', $subject)->where('school_id', $school)->exists();
    }

    private function sectionWithinSchool(int $school, int $section): bool
    {
        return DB::table('sections as s')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('s.id', $section)
            ->where('g.school_id', $school)
            ->exists();
    }
}
