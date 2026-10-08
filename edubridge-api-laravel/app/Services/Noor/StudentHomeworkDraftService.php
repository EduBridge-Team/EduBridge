<?php

namespace App\Services\Noor;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class StudentHomeworkDraftService
{
    /**
     * Generate a review-only homework draft. This method never persists data.
     *
     * @return array{title:string,description:string,subject:?string,due_in_days:int}
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
            'مهمتك إنشاء مسودة واجب تعليمية قصيرة للمعلم اعتماداً فقط على سياق الطالب المرفق.',
            'لا تقدّم تشخيصاً طبياً أو نفسياً، ولا تضف معلومات عن أداء الطالب غير موجودة في السياق.',
            'اكتب واجباً مناسباً للتعلم ويمكن للمعلم مراجعته وتعديله قبل النشر.',
            'أعد JSON فقط بدون Markdown وبالمفاتيح التالية حصراً: title, description, subject, due_in_days.',
            'title بين 3 و120 حرفاً.',
            'description بين 10 و1200 حرف ويشرح المطلوب بوضوح وباختصار.',
            'subject نص قصير أو null.',
            'due_in_days عدد صحيح من 1 إلى 30.',
        ]);

        $user = implode("\n", array_filter([
            "سياق الطالب الآمن من EduBridge:\n{$safeContext}",
            $focus === '' ? null : 'تركيز المعلم للمسودة: '.mb_substr($focus, 0, 500),
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
                    'max_completion_tokens' => 450,
                ]);
        } catch (ConnectionException $e) {
            throw new RuntimeException('تعذّر الاتصال بنور الآن.', 0, $e);
        }

        if (!$response->successful()) {
            throw new RuntimeException(
                $response->status() === 429
                    ? 'نور مشغول قليلاً. حاول مجدداً بعد لحظة.'
                    : 'تعذّر إنشاء مسودة الواجب الآن.',
            );
        }

        $content = trim((string) $response->json('choices.0.message.content', ''));
        $draft = json_decode($content, true);
        if (!is_array($draft)) {
            throw new RuntimeException('وصلت مسودة غير مكتملة من نور.');
        }

        $title = trim((string) ($draft['title'] ?? ''));
        $description = trim((string) ($draft['description'] ?? ''));
        $subject = isset($draft['subject']) ? trim((string) $draft['subject']) : null;
        $dueInDays = (int) ($draft['due_in_days'] ?? 7);

        if (mb_strlen($title) < 3 || mb_strlen($description) < 10) {
            throw new RuntimeException('وصلت مسودة غير مكتملة من نور.');
        }

        return [
            'title' => mb_substr($title, 0, 120),
            'description' => mb_substr($description, 0, 1200),
            'subject' => $subject === '' ? null : mb_substr($subject, 0, 120),
            'due_in_days' => max(1, min(30, $dueInDays)),
        ];
    }
}
