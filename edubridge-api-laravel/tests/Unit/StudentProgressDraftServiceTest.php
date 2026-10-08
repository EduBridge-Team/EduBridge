<?php

namespace Tests\Unit;

use App\Services\Noor\StudentProgressDraftService;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

class StudentProgressDraftServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config()->set('services.groq.key', 'test-key');
        config()->set('services.groq.model', 'test-model');
    }

    public function test_it_returns_a_review_only_structured_progress_draft(): void
    {
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [[
                    'message' => [
                        'content' => json_encode([
                            'specialist_notes' => 'أظهر الطالب تحسناً في إكمال الأنشطة المسجلة مع استمرار الحاجة إلى متابعة القراءة.',
                            'recommendations' => 'الاستمرار بأنشطة قراءة قصيرة مع دعم بصري ومراجعة أسبوعية للتقدم.',
                            'plan_evaluation' => 'الخطة مناسبة حالياً وفق البيانات المتاحة وتحتاج متابعة أثر الأنشطة القادمة.',
                        ], JSON_UNESCAPED_UNICODE),
                    ],
                ]],
            ], 200),
        ]);

        $draft = app(StudentProgressDraftService::class)->generate([
            'student' => ['display_name' => 'سارة'],
            'recent_progress' => [['progress_percentage' => 65]],
        ]);

        $this->assertStringContainsString('تحسناً', $draft['specialist_notes']);
        $this->assertStringContainsString('قراءة', $draft['recommendations']);
        $this->assertNotEmpty($draft['plan_evaluation']);

        Http::assertSent(function ($request) {
            $payload = $request->data();

            return ($payload['response_format']['type'] ?? null) === 'json_object'
                && ($payload['model'] ?? null) === 'test-model';
        });
    }

    public function test_it_clamps_generated_fields(): void
    {
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [[
                    'message' => [
                        'content' => json_encode([
                            'specialist_notes' => str_repeat('ملاحظة تعليمية ', 120),
                            'recommendations' => str_repeat('توصية تعليمية ', 120),
                            'plan_evaluation' => str_repeat('تقييم الخطة ', 120),
                        ], JSON_UNESCAPED_UNICODE),
                    ],
                ]],
            ], 200),
        ]);

        $draft = app(StudentProgressDraftService::class)->generate(['student' => ['age' => 10]]);

        $this->assertLessThanOrEqual(1000, mb_strlen($draft['specialist_notes']));
        $this->assertLessThanOrEqual(1000, mb_strlen($draft['recommendations']));
        $this->assertLessThanOrEqual(1000, mb_strlen($draft['plan_evaluation']));
    }

    public function test_it_rejects_invalid_model_output(): void
    {
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [[
                    'message' => ['content' => '{"specialist_notes":"قصير"}'],
                ]],
            ], 200),
        ]);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('مسودة غير مكتملة');

        app(StudentProgressDraftService::class)->generate(['student' => ['age' => 10]]);
    }
}
