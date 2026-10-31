<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaBulkPromotionController extends Controller
{

    /**
     * The caller must explicitly confirm the IDs shown in a recent preview.
     * Every student is revalidated before any write; the batch is all-or-nothing.
     */
    public function approve(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $org = $request->attributes->get('organization');
        if (!$org || (($organizationSlug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia') && (int) $request->attributes->get('managed_school') !== $school)
            || !DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $data = $request->validate([
            'source_section_id' => ['required', 'integer'],
            'target_section_id' => ['required', 'integer', 'different:source_section_id'],
            'promoted_on' => ['required', 'date_format:Y-m-d'],
            'outcome' => ['sometimes', 'in:promoted,repeated'],
            'enrollment_ids' => ['required', 'array', 'min:1', 'max:500'],
            'enrollment_ids.*' => ['required', 'integer', 'distinct'],
            'confirm' => ['required', 'accepted'],
        ]);

        return DB::transaction(function () use ($org, $school, $data) {
            // Lock both sections in a fixed order to serialize competing promotion
            // and enrollment/transfer operations targeting the same destination.
            $locked = DB::table('sections')->whereIn('id', [
                $data['source_section_id'], $data['target_section_id'],
            ])->orderBy('id')->lockForUpdate()->get()->keyBy('id');
            if ($locked->count() !== 2) return response()->json(['error' => 'الشعبة غير موجودة'], 404);

            $sections = DB::table('sections as s')
                ->join('grades as g', 'g.id', '=', 's.grade_id')
                ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
                ->where('g.school_id', $school)->where('y.school_id', $school)
                ->whereIn('s.id', [$data['source_section_id'], $data['target_section_id']])
                ->select('s.id', 's.capacity', 's.academic_year_id',
                    'g.position as grade_position', 'y.starts_on as year_starts_on')
                ->get()->keyBy('id');
            $source = $sections->get($data['source_section_id']);
            $target = $sections->get($data['target_section_id']);
            if (!$source || !$target || $target->year_starts_on <= $source->year_starts_on
                || (int) $target->grade_position !== (int) $source->grade_position + (($data['outcome'] ?? 'promoted') === 'repeated' ? 0 : 1)
                || $data['promoted_on'] < $target->year_starts_on) {
                return response()->json(['error' => 'الصف أو السنة أو تاريخ الترفيع غير صالح'], 422);
            }

            $ids = $data['enrollment_ids'];
            $rows = DB::table('student_enrollments as e')
                ->join('children as c', 'c.id', '=', 'e.child_id')
                ->whereIn('e.id', $ids)->where('e.section_id', $source->id)
                ->where('e.status', 'active')->where('c.organization_id', $org->id)
                ->select('e.id', 'e.child_id', 'e.enrolled_on')->orderBy('e.id')->get();
            if ($rows->count() !== count($ids)) {
                return response()->json(['error' => 'تغيّرت التسجيلات منذ المعاينة، أعد المعاينة'], 409);
            }
            // Lock students in stable order, as with individual enrollment/promotion.
            foreach ($rows->pluck('child_id')->sort()->unique() as $childId) {
                DB::table('children')->where('id', $childId)->lockForUpdate()->first();
            }
            $occupied = DB::table('student_enrollments')->where('section_id', $target->id)
                ->where('status', 'active')->count();
            if ($target->capacity !== null && $occupied + $rows->count() > (int) $target->capacity) {
                return response()->json(['error' => 'لم تعد المقاعد تكفي لجميع الطلاب، أعد المعاينة'], 409);
            }
            foreach ($rows as $row) {
                if ($data['promoted_on'] < $row->enrolled_on) {
                    return response()->json(['error' => 'تاريخ الترفيع غير صالح لأحد الطلاب'], 422);
                }
                if (DB::table('student_enrollments')->where('child_id', $row->child_id)
                    ->where('section_id', $target->id)->exists()
                    || DB::table('student_enrollments as e')
                        ->join('sections as s', 's.id', '=', 'e.section_id')
                        ->where('e.child_id', $row->child_id)
                        ->where('s.academic_year_id', $target->academic_year_id)
                        ->where('e.status', 'active')->exists()) {
                    return response()->json(['error' => 'أصبح أحد الطلاب مسجلًا في السنة المستقبلة، أعد المعاينة'], 409);
                }
            }
            foreach ($rows as $row) {
                $closed = DB::table('student_enrollments')->where('id', $row->id)->where('status', 'active')
                    ->update(['status' => 'transferred', 'left_on' => $data['promoted_on'], 'updated_at' => now()]);
                if ($closed !== 1) throw new \RuntimeException('Enrollment changed during bulk promotion');
                DB::table('student_enrollments')->insert([
                    'section_id' => $target->id, 'child_id' => $row->child_id,
                    'status' => 'active', 'enrolled_on' => $data['promoted_on'],
                    'left_on' => null, 'created_at' => now(), 'updated_at' => now(),
                ]);
            }
            return response()->json(['promoted' => true, 'promoted_count' => $rows->count()], 201);
        }, 3);
    }

    public function preview(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $org = $request->attributes->get('organization');
        if (!$org || (($organizationSlug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia') && (int) $request->attributes->get('managed_school') !== $school)
            || !DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $data = $request->validate([
            'source_section_id' => ['required', 'integer'],
            'target_section_id' => ['required', 'integer', 'different:source_section_id'],
            'promoted_on' => ['required', 'date_format:Y-m-d'],
            'outcome' => ['sometimes', 'in:promoted,repeated'],
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
            || (int) $target->grade_position !== (int) $source->grade_position + (($data['outcome'] ?? 'promoted') === 'repeated' ? 0 : 1)
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
