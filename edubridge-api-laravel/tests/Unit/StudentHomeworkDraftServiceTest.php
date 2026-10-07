<?php

namespace Tests\Unit;

use App\Services\Noor\StudentHomeworkDraftService;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

class StudentHomeworkDraftServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config()->set('services.groq.key', 'test-key');
        config()->set('services.groq.model', 'test-model');
    }

    public function test_it_returns_a_review_only_structured_homework_draft(): void
    {
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [[
                    'message' => [
                        'content' => json_encode([
                            'title' => 'مراجعة القراءة',
                            'description' => 'اقرأ الفقرة القصيرة ثم حدّد الفكرة الرئيسية واكتب جملة واحدة عنها.',
                            'subject' => 'اللغة العربية',
                            'due_in_days' => 5,
                        ], JSON_UNESCAPED_UNICODE),
                    ],
                ]],
            ], 200),
        ]);

        $draft = app(StudentHomeworkDraftService::class)->generate([
            'student' => ['display_name' => 'سارة', 'learning_style' => 'بصري'],
            'recent_lessons' => [['title' => 'الفكرة الرئيسية']],
        ]);

        $this->assertSame('مراجعة القراءة', $draft['title']);
        $this->assertSame('اللغة العربية', $draft['subject']);
        $this->assertSame(5, $draft['due_in_days']);
        $this->assertStringContainsString('الفكرة الرئيسية', $draft['description']);

        Http::assertSent(function ($request) {
            $payload = $request->data();

            return ($payload['response_format']['type'] ?? null) === 'json_object'
                && ($payload['model'] ?? null) === 'test-model';
        });
    }

    public function test_it_clamps_due_days_and_output_lengths(): void
    {
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [[
                    'message' => [
                        'content' => json_encode([
                            'title' => str_repeat('أ', 150),
                            'description' => str_repeat('وصف تعليمي مناسب ', 100),
                            'subject' => str_repeat('مادة', 50),
                            'due_in_days' => 90,
                        ], JSON_UNESCAPED_UNICODE),
                    ],
                ]],
            ], 200),
        ]);

        $draft = app(StudentHomeworkDraftService::class)->generate(['student' => ['age' => 10]]);

        $this->assertLessThanOrEqual(120, mb_strlen($draft['title']));
        $this->assertLessThanOrEqual(1200, mb_strlen($draft['description']));
        $this->assertLessThanOrEqual(120, mb_strlen((string) $draft['subject']));
        $this->assertSame(30, $draft['due_in_days']);
    }

    public function test_it_rejects_invalid_model_output(): void
    {
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [[
                    'message' => ['content' => '{"title":"x"}'],
                ]],
            ], 200),
        ]);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('مسودة غير مكتملة');

        app(StudentHomeworkDraftService::class)->generate(['student' => ['age' => 10]]);
    }
}
