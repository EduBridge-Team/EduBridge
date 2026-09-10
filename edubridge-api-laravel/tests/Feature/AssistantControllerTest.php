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
            'services.gemini.key' => 'test-key',
            'services.gemini.model' => 'test-model',
        ]);

        Http::fake(fn () => Http::response([
            'steps' => [[
                'type' => 'model_output',
                'content' => [[
                    'type' => 'text',
                    'text' => 'لنشرح الفكرة بخطوات بسيطة.',
                ]],
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
            $sent->url() === 'https://generativelanguage.googleapis.com/v1beta/interactions'
            && $sent['model'] === 'test-model'
            && $sent['store'] === false
            && $sent->hasHeader('x-goog-api-key', 'test-key')
            && ! str_contains(json_encode($sent->data()), 'test@example.com')
            && ! str_contains(json_encode($sent->data()), '0599123456')
            && str_contains($sent['system_instruction'], 'معلّم')
        );
    }

    public function test_it_reports_when_the_server_key_is_not_configured(): void
    {
        config(['services.gemini.key' => null]);

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
}
