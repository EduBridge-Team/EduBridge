<?php

namespace App\Services\Noor;

class StudentInsightService
{
    public function actions(array $context, string $role): array
    {
        $signals = collect($context['signals'] ?? [])->keyBy('type');
        $actions = [];

        if ($signals->has('homework_follow_up')) {
            $actions[] = $this->make('follow_up_homework', 'high', 'متابعة الواجبات غير المكتملة', $signals->get('homework_follow_up')['message'], 'حلّل الواجبات التي تحتاج متابعة واقترح خطوة تعليمية عملية قصيرة.');
        }
        if ($signals->has('low_progress')) {
            $actions[] = $this->make('reinforce_recent_learning', 'high', 'تعزيز المهارات ذات التقدم المنخفض', $signals->get('low_progress')['message'], 'حلّل آخر تقدم مسجل واقترح نشاط تعزيز مناسب اعتماداً على البيانات المتاحة فقط.');
        }
        if ($signals->has('missing_progress')) {
            $actions[] = $this->make('refresh_progress', 'medium', $role === 'parent' ? 'طلب تحديث عن التقدم' : 'تحديث التقدم الأسبوعي', $signals->get('missing_progress')['message'], $role === 'parent' ? 'ما الأسئلة القصيرة التي يمكنني طرحها على فريق المتابعة لفهم تقدم الطالب؟' : 'اقترح نقاطاً قصيرة يجب مراجعتها عند إعداد تحديث التقدم القادم.');
        }
        if ($actions === []) {
            $actions[] = $this->make('continue_plan', 'low', 'مواصلة الخطة ومراجعة التقدم', 'لا تظهر في البيانات الحالية إشارة متابعة عاجلة.', 'لخّص التقدم الحالي واقترح الخطوة التعليمية التالية مع سببها.');
        }

        return array_slice($actions, 0, 3);
    }

    private function make(string $type, string $priority, string $title, string $reason, string $prompt): array
    {
        return compact('type', 'priority', 'title', 'reason') + ['suggested_prompt' => $prompt];
    }
}
