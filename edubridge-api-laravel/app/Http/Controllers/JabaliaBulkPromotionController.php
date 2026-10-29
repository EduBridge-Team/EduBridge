<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaBulkPromotionController extends Controller
{
    public function preview(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $org = $request->attributes->get('organization');
        if (!$org || $organizationSlug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia'
            || !DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $data = $request->validate([
            'source_section_id' => ['required', 'integer'],
            'target_section_id' => ['required', 'integer', 'different:source_section_id'],
            'promoted_on' => ['required', 'date_format:Y-m-d'],
        ]);
        $sections = DB::table('sections as s')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
            ->where('g.school_id', $school)->where('y.school_id', $school)
            ->whereIn('s.id', [$data['source_section_id'], $data['target_section_id']])
            ->select('s.id', 's.capacity', 's.academic_year_id',
                'g.position as grade_position', 'y.starts_on as year_starts_on')->get()->keyBy('id');
        $source = $sections->get($data['source_section_id']);
        $target = $sections->get($data['target_section_id']);
        if (!$source || !$target || $target->year_starts_on <= $source->year_starts_on
            || (int) $target->grade_position !== (int) $source->grade_position + 1
            || $data['promoted_on'] < $target->year_starts_on) {
            return response()->json(['error' => 'اختر شعبة من الصف التالي وسنة لاحقة مع تاريخ ترفيع صحيح'], 422);
        }
        $occupied = DB::table('student_enrollments')->where('section_id', $target->id)
            ->where('status', 'active')->count();
        $places = $target->capacity === null ? null : max(0, (int) $target->capacity - $occupied);
        $total = DB::table('student_enrollments')->where('section_id', $source->id)->where('status', 'active')->count();
        $rows = DB::table('student_enrollments as e')
            ->join('children as c', 'c.id', '=', 'e.child_id')
            ->where('e.section_id', $source->id)->where('e.status', 'active')
            ->where('c.organization_id', $org->id)
            ->select('e.id', 'e.child_id', 'e.enrolled_on', 'c.name as child_name')
            ->orderBy('e.id')->limit(500)->get();
        $results = [];
        $eligible = 0;
        foreach ($rows as $row) {
            $reason = null;
            if ($data['promoted_on'] < $row->enrolled_on) $reason = 'تاريخ الترفيع يسبق تسجيل الطالب';
            elseif (DB::table('student_enrollments')->where('child_id', $row->child_id)
                ->where('section_id', $target->id)->exists()) $reason = 'للطالب تسجيل سابق في الشعبة المستقبلة';
            elseif (DB::table('student_enrollments as e')->join('sections as s', 's.id', '=', 'e.section_id')
                ->where('e.child_id', $row->child_id)->where('s.academic_year_id', $target->academic_year_id)
                ->where('e.status', 'active')->exists()) $reason = 'للطالب تسجيل نشط في السنة المستقبلة';
            elseif ($places !== null && $eligible >= $places) $reason = 'لا توجد مقاعد متاحة';
            if ($reason === null) $eligible++;
            $results[] = [
                'enrollment_id' => $row->id, 'child_id' => $row->child_id,
                'child_name' => $row->child_name, 'eligible' => $reason === null,
                'reason' => $reason,
            ];
        }
        return response()->json([
            'preview_only' => true, 'source_section_id' => $source->id,
            'target_section_id' => $target->id, 'promoted_on' => $data['promoted_on'],
            'occupied' => $occupied, 'capacity' => $target->capacity,
            'eligible_count' => $eligible, 'blocked_count' => count($results) - $eligible,
            'rows' => $results, 'limit' => 500, 'total_active' => $total,
            'truncated' => $total > 500,
            'notice' => 'المعاينة لا تحفظ أي تغييرات؛ يجب إعادة التحقق من الأهلية والسعة عند الاعتماد. لا تستخدم النتائج الجزئية لاعتماد الدفعة كاملة.',
        ]);
    }
}
