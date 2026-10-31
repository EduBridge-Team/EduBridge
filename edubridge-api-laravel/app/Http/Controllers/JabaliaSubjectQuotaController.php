<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaSubjectQuotaController extends Controller
{
    private function scoped(Request $request, string $slug, int $school): bool
    {
        $org = $request->attributes->get('organization');
        return $slug === 'jabalia' && ($org->slug ?? null) === 'jabalia'
            && DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists();
    }

    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->scoped($request, $organizationSlug, $school))
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        return response()->json(['quotas' => DB::table('jabalia_section_subject_quotas')
            ->where('school_id', $school)->orderBy('section_id')->orderBy('subject_id')->get(),
            'note' => 'الحصص الأسبوعية تحدد لكل شعبة ومادة؛ لا توزع الأوقات غير المحددة تلقائيًا']);
    }

    public function update(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->scoped($request, $organizationSlug, $school))
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);

        $data = $request->validate([
            'section_id' => ['required', 'integer'],
            'subject_id' => ['required', 'integer'],
            'weekly_periods' => ['required', 'integer', 'between:0,35'],
        ]);
        $section = DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('s.id', $data['section_id'])->where('g.school_id', $school)
            ->select('s.id', 's.academic_year_id')->first();
        if (!$section || !DB::table('subjects')->where('id', $data['subject_id'])->where('school_id', $school)->exists())
            return response()->json(['error' => 'الشعبة أو المادة خارج نطاق المدرسة'], 422);

        return DB::transaction(function () use ($school, $section, $data) {
            // Keep the same school-level lock order as timetable lesson creation.
            // Otherwise a concurrent lesson insert can race a quota reduction.
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            DB::table('sections')->where('id', $section->id)->lockForUpdate()->first();
            $current = DB::table('timetable_entries')
                ->where('section_id', $section->id)->where('subject_id', $data['subject_id'])
                ->where('academic_year_id', $section->academic_year_id)->count();
            if ($current > $data['weekly_periods'])
                return response()->json(['error' => 'يوجد بالفعل عدد حصص يتجاوز الحد الجديد'], 409);

            DB::table('jabalia_section_subject_quotas')->updateOrInsert(
                ['section_id' => $section->id, 'subject_id' => $data['subject_id']],
                ['school_id' => $school, 'weekly_periods' => $data['weekly_periods'], 'updated_at' => now()]
            );
            return response()->json(['quota' => $data, 'scheduled' => $current]);
        });
    }
}
