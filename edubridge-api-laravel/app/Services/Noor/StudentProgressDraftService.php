<?php

namespace App\Services\Noor;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class StudentProgressDraftService
{
    /**
     * Generate review-only specialist progress text. This method never persists data.
     *
     * @return array{specialist_notes:string,recommendations:string,plan_evaluation:string}
     */
    public function generate(array $context, ?string $focus = null): array
    {
        $apiKey = config('services.groq.key');
        if (!$apiKey) {
            throw new RuntimeException('مساعد نور غير مفعّل على الخادم بعد.');
        }

        $safeContext = mb_substr(
            json_encode($context, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '{}',
            0,
            3500,
        );
        $focus = trim((string) $focus);

        $system = implode("\n", [
            'أنت نور، مساعد EduBridge التعليمي.',
            'اكتب مسودة تقدم أسبوعي للمختص اعتماداً فقط على سياق الطالب المرفق.',
            'لا تقدّم تشخيصاً طبياً أو نفسياً ولا تختلق ملاحظة لم يسجلها المعلم أو المختص.',
            'افصل بوضوح بين الملاحظات المستندة إلى البيانات والتوصيات التعليمية المقترحة.',
            'أعد JSON فقط بدون Markdown وبالمفاتيح التالية حصراً: specialist_notes, recommendations, plan_evaluation.',
            'كل حقل نص عربي واضح وقصير، ويمكن أن يكون plan_evaluation فارغاً إذا لم توجد بيانات كافية عن الخطة.',
            'لا تتجاوز 1000 حرف لكل حقل.',
        ]);

        $user = implode("\n", array_filter([
            "سياق الطالب الآمن من EduBridge:\n{$safeContext}",
            $focus === '' ? null : 'تركيز المختص للمسودة: '.mb_substr($focus, 0, 500),
        ]));

        try {
            $response = Http::withToken($apiKey)
                ->acceptJson()
                ->timeout(35)
                ->post('https://api.groq.com/openai/v1/chat/completions', [
                    'model' => config('services.groq.model'),
                    'messages' => [
                        ['role' => 'system', 'content' => $system],
                        ['role' => 'user', 'content' => $user],
                    ],
                    'response_format' => ['type' => 'json_object'],
                    'max_completion_tokens' => 550,
                ]);
        } catch (ConnectionException $e) {
            throw new RuntimeException('تعذّر الاتصال بنور الآن.', 0, $e);
        }

        if (!$response->successful()) {
            throw new RuntimeException(
                $response->status() === 429
                    ? 'نور مشغول قليلاً. حاول مجدداً بعد لحظة.'
                    : 'تعذّر إنشاء مسودة التقدم الآن.',
            );
        }

        $content = trim((string) $response->json('choices.0.message.content', ''));
        $draft = json_decode($content, true);
        if (!is_array($draft)) {
            throw new RuntimeException('وصلت مسودة غير مكتملة من نور.');
        }

        $notes = trim((string) ($draft['specialist_notes'] ?? ''));
        $recommendations = trim((string) ($draft['recommendations'] ?? ''));
        $planEvaluation = trim((string) ($draft['plan_evaluation'] ?? ''));

        if (mb_strlen($notes) < 10 || mb_strlen($recommendations) < 5) {
            throw new RuntimeException('وصلت مسودة غير مكتملة من نور.');
        }

        return [
            'specialist_notes' => mb_substr($notes, 0, 1000),
            'recommendations' => mb_substr($recommendations, 0, 1000),
            'plan_evaluation' => mb_substr($planEvaluation, 0, 1000),
        ];
    }
}
