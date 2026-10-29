<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaAnnualPromotionController extends Controller
{
    public function promote(Request $request, string $organizationSlug, int $school, int $enrollment): JsonResponse
    {
        $org = $request->attributes->get('organization');
        if (!$org || $organizationSlug !== 'jabalia' || $org->slug !== 'jabalia'
            || !DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'target_section_id' => ['required', 'integer'],
            'promoted_on' => ['required', 'date_format:Y-m-d'],
        ]);

        return DB::transaction(function () use ($org, $school, $enrollment, $data) {
            $source = DB::table('student_enrollments as e')
                ->join('sections as s', 's.id', '=', 'e.section_id')
                ->join('grades as g', 'g.id', '=', 's.grade_id')
                ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
                ->join('children as c', 'c.id', '=', 'e.child_id')
                ->where('e.id', $enrollment)->where('g.school_id', $school)
                ->where('y.school_id', $school)->where('c.organization_id', $org->id)
                ->select('e.id', 'e.child_id', 'e.status', 'e.enrolled_on',
                    's.academic_year_id', 'g.position as grade_position', 'y.starts_on as year_starts_on')
                ->first();
            if (!$source) return response()->json(['error' => 'التسجيل غير موجود'], 404);

            DB::table('children')->where('id', $source->child_id)->lockForUpdate()->first();
            if ($source->status !== 'active') {
                return response()->json(['error' => 'التسجيل السابق غير نشط'], 409);
            }

            $target = DB::table('sections as s')
                ->join('grades as g', 'g.id', '=', 's.grade_id')
                ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
                ->where('s.id', $data['target_section_id'])
                ->where('g.school_id', $school)->where('y.school_id', $school)
                ->select('s.id', 's.capacity', 's.academic_year_id',
                    'g.position as grade_position', 'y.starts_on as year_starts_on')
                ->first();
            if (!$target || $target->year_starts_on <= $source->year_starts_on
                || (int) $target->grade_position !== (int) $source->grade_position + 1) {
                return response()->json(['error' => 'يجب اختيار شعبة في الصف التالي وسنة دراسية لاحقة'], 422);
            }
            if ($data['promoted_on'] < $target->year_starts_on || $data['promoted_on'] < $source->enrolled_on) {
                return response()->json(['error' => 'تاريخ الترفيع غير متوافق مع تواريخ الدراسة'], 422);
            }

            // Every operation that fills a section locks the same destination row.
            DB::table('sections')->where('id', $target->id)->lockForUpdate()->first();
            if ($target->capacity !== null &&
                DB::table('student_enrollments')->where('section_id', $target->id)
                    ->where('status', 'active')->count() >= (int) $target->capacity) {
                return response()->json(['error' => 'الشعبة المستقبلة ممتلئة'], 409);
            }
            if (DB::table('student_enrollments')->where('child_id', $source->child_id)
                ->where('section_id', $target->id)->exists()) {
                return response()->json(['error' => 'سبق تسجيل الطالب في الشعبة المستقبلة'], 409);
            }
            if (DB::table('student_enrollments as e')->join('sections as s', 's.id', '=', 'e.section_id')
                ->where('e.child_id', $source->child_id)
                ->where('s.academic_year_id', $target->academic_year_id)
                ->where('e.status', 'active')->exists()) {
                return response()->json(['error' => 'للطالب تسجيل نشط في السنة المستقبلة'], 409);
            }

            // Retain source enrollment; promotion only closes its active status.
            DB::table('student_enrollments')->where('id', $source->id)->where('status', 'active')
                ->update(['status' => 'transferred', 'left_on' => $data['promoted_on'], 'updated_at' => now()]);
            $newId = DB::table('student_enrollments')->insertGetId([
                'section_id' => $target->id, 'child_id' => $source->child_id,
                'status' => 'active', 'enrolled_on' => $data['promoted_on'],
                'left_on' => null, 'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['promoted' => true, 'new_enrollment_id' => $newId], 201);
        });
    }
}
