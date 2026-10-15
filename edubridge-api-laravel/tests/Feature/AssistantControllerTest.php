<?php

namespace Tests\Feature;

use App\Http\Controllers\AssistantController;
use Illuminate\Http\Client\Request as HttpRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AssistantControllerTest extends TestCase
{
    public function test_it_returns_the_assistant_reply_without_storing_the_response(): void
    {
        config([
            'services.groq.key' => 'test-key',
            'services.groq.model' => 'test-model',
        ]);

        Http::fake(fn () => Http::response([
            'choices' => [[
                'message' => [
                    'role' => 'assistant',
                    'content' => 'لنشرح الفكرة بخطوات بسيطة.',
                ],
            ]],
        ]));

        $request = Request::create(
            '/api/assistant/chat',
            'POST',
            content: json_encode([
                'messages' => [[
                    'role' => 'user',
                    'content' => 'راسلني test@example.com أو 0599123456 واشرح الدرس',
                ]],
                'context' => 'عنوان الدرس: الألوان',
            ], JSON_THROW_ON_ERROR),
        );
        $request->headers->set('Content-Type', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'teacher']);

        $response = app(AssistantController::class)->chat($request);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame(
            'لنشرح الفكرة بخطوات بسيطة.',
            json_decode($response->getContent(), true)['reply'],
        );
        Http::assertSent(fn (HttpRequest $sent) =>
            $sent->url() === 'https://api.groq.com/openai/v1/chat/completions'
            && $sent['model'] === 'test-model'
            && $sent['max_completion_tokens'] === 1600
            && ! isset($sent['reasoning_effort'])
            && $sent->hasHeader('Authorization', 'Bearer test-key')
            && ! str_contains(json_encode($sent->data()), 'test@example.com')
            && ! str_contains(json_encode($sent->data()), '0599123456')
            && str_contains($sent['messages'][0]['content'], 'معلّم')
        );
    }

    public function test_it_instructs_noor_not_to_invent_platform_facts_when_context_is_missing(): void
    {
        config([
            'services.groq.key' => 'test-key',
            'services.groq.model' => 'test-model',
        ]);

        Http::fake(fn () => Http::response([
            'choices' => [[
                'message' => [
                    'role' => 'assistant',
                    'content' => 'افتح صفحة التقدم حتى أتمكن من قراءة البيانات الفعلية.',
                ],
            ]],
        ]));

        $request = Request::create(
            '/api/assistant/chat',
            'POST',
            content: json_encode([
                'messages' => [[
                    'role' => 'user',
                    'content' => 'كيف كان تقدم ابني هذا الأسبوع؟',
                ]],
            ], JSON_THROW_ON_ERROR),
        );
        $request->headers->set('Content-Type', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => 9, 'role' => 'parent']);

        $response = app(AssistantController::class)->chat($request);

        $this->assertSame(200, $response->getStatusCode());
        Http::assertSent(function (HttpRequest $sent): bool {
            $system = (string) ($sent['messages'][0]['content'] ?? '');

            return str_contains($system, 'يجب أن تكون موجودة صراحة في سياق الشاشة')
                && str_contains($system, 'لا تخمّن')
                && ! str_contains($system, 'سياق EduBridge الحالي (مرجعي فقط):');
        });
    }

    public function test_it_reports_when_the_server_key_is_not_configured(): void
    {
        config(['services.groq.key' => null]);

        $request = Request::create(
            '/api/assistant/chat',
            'POST',
            content: json_encode([
                'messages' => [['role' => 'user', 'content' => 'مرحباً']],
            ], JSON_THROW_ON_ERROR),
        );
        $request->headers->set('Content-Type', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);

        $response = app(AssistantController::class)->chat($request);

        $this->assertSame(503, $response->getStatusCode());
    }

    public function test_gpt_oss_uses_low_reasoning_to_reserve_tokens_for_visible_answers(): void
    {
        config(['services.groq.key' => 'test-key', 'services.groq.model' => 'openai/gpt-oss-20b']);
        Http::fake(fn () => Http::response([
            'choices' => [[
                'finish_reason' => 'stop',
                'message' => ['content' => 'النتيجة كاملة.'],
            ]],
        ]));

        $request = Request::create('/api/assistant/chat', 'POST', content: json_encode([
            'messages' => [['role' => 'user', 'content' => 'اشرح الجمع']],
        ], JSON_THROW_ON_ERROR));
        $request->headers->set('Content-Type', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);

        $response = app(AssistantController::class)->chat($request);
        $this->assertSame(200, $response->status());
        $this->assertSame(false, $response->getData(true)['incomplete']);
        Http::assertSent(fn (HttpRequest $sent) =>
            $sent['model'] === 'openai/gpt-oss-20b'
            && $sent['reasoning_effort'] === 'low'
            && $sent['max_completion_tokens'] === 1600
        );
    }

    public function test_token_limited_replies_explicitly_offer_continuation(): void
    {
        config(['services.groq.key' => 'test-key', 'services.groq.model' => 'test-model']);
        Http::fake(fn () => Http::response([
            'choices' => [[
                'finish_reason' => 'length',
                'message' => ['content' => 'الخطوة الأولى: نجمع العددين'],
            ]],
        ]));

        $request = Request::create('/api/assistant/chat', 'POST', content: json_encode([
            'messages' => [['role' => 'user', 'content' => 'اشرح الخطوات']],
        ], JSON_THROW_ON_ERROR));
        $request->headers->set('Content-Type', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);

        $response = app(AssistantController::class)->chat($request);
        $this->assertSame(200, $response->status());
        $this->assertTrue($response->getData(true)['incomplete']);
        $this->assertStringContainsString('الخطوة الأولى', $response->getData(true)['reply']);
        $this->assertStringContainsString('أكمل الإجابة', $response->getData(true)['reply']);
    }
}
