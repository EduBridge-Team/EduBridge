<?php

namespace App\Http\Controllers\Concerns;

trait WeeklyReportSpecialistHelpers
{
    private function specialistNotesPayload(
        string $notes,
        string $recommendations,
        string $planEvaluation,
        $appropriate,
        $mood
    ): string {
        $sections = [$notes];

        if ($recommendations !== '') {
            $sections[] = 'التوصيات: ' . $recommendations;
        }

        if ($appropriate !== null) {
            $isAppropriate = filter_var($appropriate, FILTER_VALIDATE_BOOLEAN);
            $sections[] = 'ملاءمة الخطة: ' . ($isAppropriate ? 'مناسبة' : 'تحتاج تعديلاً');
        }

        if ($planEvaluation !== '') {
            $sections[] = 'تقييم الخطة: ' . $planEvaluation;
        }

        if ($mood !== null) {
            $sections[] = 'تقييم التفاعل: ' . (int) $mood . '/5';
        }

        return implode("\n", $sections);
    }
}
