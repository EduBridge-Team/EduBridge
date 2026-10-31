<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class SchoolPromotionRoster
{
    public function load(int $school, int $sourceYear, int $targetYear): array
    {
        $years = DB::table('academic_years')->where('school_id', $school)->whereIn('id', [$sourceYear, $targetYear])->get()->keyBy('id');
        $source = $years->get($sourceYear); $target = $years->get($targetYear);
        if (!$source || !$target || $targetYear <= $sourceYear || $target->starts_on <= $source->starts_on) {
            throw ValidationException::withMessages(['target_year_id' => ['Choose a later school year']]);
        }
        $students = DB::table('student_enrollments as e')->join('sections as s', 's.id', '=', 'e.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')->join('children as c', 'c.id', '=', 'e.child_id')
            ->where('g.school_id', $school)->where('s.academic_year_id', $sourceYear)->where('e.status', 'active')
            ->orderBy('e.id')->limit(5001)->get(['e.id as enrollment_id', 'e.child_id', 'c.name as child_name',
                'g.id as source_grade_id', 'g.position as source_grade_position', 's.id as source_section_id', 'e.enrolled_on'])->map(fn ($row) => (array) $row)->all();
        $sections = DB::table('sections as s')->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('g.school_id', $school)->where('s.academic_year_id', $targetYear)->orderBy('s.id')
            ->get(['s.id', 's.name', 's.capacity', 'g.id as grade_id', 'g.position as grade_position'])->map(function ($section) {
                return ['id' => (int) $section->id, 'name' => $section->name, 'grade_id' => (int) $section->grade_id,
                    'grade_position' => (int) $section->grade_position, 'capacity' => $section->capacity === null ? null : (int) $section->capacity,
                    'occupied' => DB::table('student_enrollments')->where('section_id', $section->id)->where('status', 'active')->count()];
            })->all();
        return ['school_id' => $school, 'source_year_id' => $sourceYear, 'target_year_id' => $targetYear,
            'complete' => count($students) <= 5000 && count(array_unique(array_column($students, 'child_id'))) === count($students), 'students' => $students, 'target_sections' => $sections,
            'target_starts_on' => $target->starts_on,
            'revision' => hash('sha256', json_encode([$school, $sourceYear, $targetYear, $target->starts_on, $students, $sections], JSON_UNESCAPED_UNICODE))];
    }

    public function validateDecisions(array $roster, array $decisions): array
    {
        $errors = []; $destinations = array_column($roster['target_sections'], null, 'id');
        $students = array_column($roster['students'], null, 'enrollment_id');
        $counts = []; $seen = [];
        if (!$roster['complete'] || !$students || count($decisions) !== count($students)) $errors[] = 'A complete decision is required for every active student';
        foreach ($decisions as $decision) {
            $id = (int) $decision['enrollment_id'];
            $student = $students[$id] ?? null;
            if (!$student || isset($seen[$id])) { $errors[] = 'Foreign or duplicate enrollment'; continue; }
            $seen[$id] = true;
            if ($student['enrolled_on'] > $roster['target_starts_on']) $errors[] = 'Progression date precedes enrollment';
            if ($decision['decision'] === 'transferred') {
                $destination = (int) ($decision['target_school_id'] ?? 0);
                if (isset($decision['target_section_id']) || $destination === $roster['school_id']
                    || !DB::table('schools as s')->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')->where('s.id', $destination)->where('s.is_active', true)->where(fn ($q) => $q->whereNull('s.organization_id')->orWhere('o.is_active', true))->exists()) $errors[] = 'Invalid transfer destination';
                continue;
            }
            $section = $destinations[$decision['target_section_id'] ?? 0] ?? null;
            $position = (int) $student['source_grade_position'] + ($decision['decision'] === 'promoted' ? 1 : 0);
            if (isset($decision['target_school_id']) || !$section || $section['grade_position'] !== $position
                || ($decision['decision'] === 'repeating' && $section['grade_id'] !== (int) $student['source_grade_id'])) {
                $errors[] = 'Invalid grade or destination'; continue;
            }
            if (DB::table('student_enrollments as e')->join('sections as s', 's.id', '=', 'e.section_id')
                ->where('e.child_id', $student['child_id'])->where('s.academic_year_id', $roster['target_year_id'])->where('e.status', 'active')->exists()) {
                $errors[] = 'Student already enrolled in target year';
            }
            $counts[$section['id']] = ($counts[$section['id']] ?? 0) + 1;
        }
        foreach ($counts as $id => $count) {
            if ($destinations[$id]['capacity'] !== null && $destinations[$id]['occupied'] + $count > $destinations[$id]['capacity']) $errors[] = 'Target section capacity exceeded';
        }
        return array_values(array_unique($errors));
    }
}
