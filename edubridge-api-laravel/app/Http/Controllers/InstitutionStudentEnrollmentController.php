<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class InstitutionStudentEnrollmentController extends Controller
{
    public function history(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $organization = $request->attributes->get('organization');
        if (!DB::table('schools')->where('id', $school)->where('organization_id', $organization->id)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $rows = DB::table('student_enrollments as se')
            ->join('sections as s', 's.id', '=', 'se.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('children as c', 'c.id', '=', 'se.child_id')
            ->where('g.school_id', $school)->where('c.organization_id', $organization->id)
            ->select('se.id', 'se.child_id', 'se.section_id', 'se.status', 'se.enrolled_on',
                'se.left_on', 'c.name as child_name', 's.name as section_name',
                'g.name as grade_name', 's.academic_year_id')
            ->orderByDesc('se.enrolled_on')->orderByDesc('se.id')->get();
        return response()->json(['enrollments' => $rows]);
    }

    public function close(Request $request, string $organizationSlug, int $school, int $enrollment): JsonResponse
    {
        $data = $request->validate(['status' => ['required', Rule::in(['withdrawn', 'transferred'])]]);
        $org = $request->attributes->get('organization');
        return DB::transaction(function () use ($org, $school, $enrollment, $data) {
            $record = $this->scopedEnrollment($org->id, $school, $enrollment);
            if (!$record) return response()->json(['error' => 'التسجيل غير موجود'], 404);
            $child = DB::table('children')->where('id', $record->child_id)->lockForUpdate()->first();
            if (!$child) return response()->json(['error' => 'الطالب غير موجود'], 404);
            $changed = DB::table('student_enrollments')->where('id', $enrollment)
                ->where('status', 'active')
                ->update(['status' => $data['status'], 'left_on' => now()->toDateString(), 'updated_at' => now()]);
            return $changed ? response()->json(['updated' => true])
                : response()->json(['error' => 'التسجيل ليس نشطًا'], 409);
        });
    }

    public function transfer(Request $request, string $organizationSlug, int $school, int $enrollment): JsonResponse
    {
        $data = $request->validate(['section_id' => ['required', 'integer']]);
        $org = $request->attributes->get('organization');
        return DB::transaction(function () use ($org, $school, $enrollment, $data) {
            $current = $this->scopedEnrollment($org->id, $school, $enrollment);
            if (!$current) return response()->json(['error' => 'التسجيل غير موجود'], 404);
            DB::table('children')->where('id', $current->child_id)->lockForUpdate()->first();
            if ($current->status !== 'active') {
                return response()->json(['error' => 'التسجيل ليس نشطًا'], 409);
            }
            $target = DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')
                ->where('s.id', $data['section_id'])->where('g.school_id', $school)
                ->select('s.id', 's.academic_year_id')->first();
            if (!$target || $target->academic_year_id !== $current->academic_year_id ||
                $target->id === $current->section_id) {
                return response()->json(['error' => 'اختر شعبة مختلفة من نفس المدرسة والسنة الدراسية'], 422);
            }
            if (DB::table('student_enrollments')->where('child_id', $current->child_id)
                ->where('section_id', $target->id)->exists()) {
                return response()->json(['error' => 'سبق تسجيل الطالب في الشعبة المطلوبة'], 409);
            }
            $activeElsewhere = DB::table('student_enrollments as se')
                ->join('sections as s', 's.id', '=', 'se.section_id')
                ->where('se.child_id', $current->child_id)->where('s.academic_year_id', $target->academic_year_id)
                ->where('se.status', 'active')->where('se.id', '!=', $current->id)->exists();
            if ($activeElsewhere) return response()->json(['error' => 'للطالب تسجيل نشط آخر في هذه السنة'], 409);
            DB::table('student_enrollments')->where('id', $current->id)
                ->update(['status' => 'transferred', 'left_on' => now()->toDateString(), 'updated_at' => now()]);
            DB::table('student_enrollments')->insert([
                'section_id' => $target->id, 'child_id' => $current->child_id,
                'status' => 'active', 'enrolled_on' => now()->toDateString(),
                'left_on' => null, 'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['transferred' => true], 201);
        });
    }

    private function scopedEnrollment(int $organization, int $school, int $id): ?object
    {
        return DB::table('student_enrollments as se')
            ->join('sections as s', 's.id', '=', 'se.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('children as c', 'c.id', '=', 'se.child_id')
            ->where('se.id', $id)->where('g.school_id', $school)
            ->where('c.organization_id', $organization)
            ->select('se.id', 'se.child_id', 'se.section_id', 'se.status', 's.academic_year_id')->first();
    }
}
