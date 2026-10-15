<?php

namespace Tests\Feature;

use App\Http\Controllers\NoorImageAnalysisController;
use Illuminate\Http\Client\Request as OutboundRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class NoorImageAnalysisTest extends TestCase
{
    private function request(UploadedFile $image): Request
    {
        $request = Request::create('/api/assistant/vision/analyze', 'POST', [
            'question' => 'اشرح هذه الصورة',
        ], [], ['image' => $image]);
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'parent']);
        return $request;
    }

    public function test_vision_remains_disabled_without_separate_model_configuration(): void
    {
        config(['services.groq.key' => 'test-key', 'services.groq.vision_model' => null]);
        Http::fake();
        $response = app(NoorImageAnalysisController::class)
            ->analyze($this->request(UploadedFile::fake()->image('lesson.png')));
        $this->assertSame(503, $response->status());
        Http::assertNothingSent();
    }

    public function test_valid_image_is_sent_only_to_configured_provider_without_local_storage(): void
    {
        config(['services.groq.key' => 'test-key', 'services.groq.vision_model' => 'test-vision-model']);
        Http::fake(['api.groq.com/*' => Http::response([
            'choices' => [['message' => ['content' => 'الصورة تعرض سؤال جمع.']]],
        ])]);
        $response = app(NoorImageAnalysisController::class)
            ->analyze($this->request(UploadedFile::fake()->image('lesson.png', 100, 100)));
        $this->assertSame(200, $response->status());
        $this->assertSame('الصورة تعرض سؤال جمع.', $response->getData(true)['reply']);
        Http::assertSent(fn (OutboundRequest $sent) =>
            $sent['model'] === 'test-vision-model'
            && $sent['max_completion_tokens'] === 1024
            && $sent['messages'][1]['content'][1]['type'] === 'image_url'
            && str_starts_with($sent['messages'][1]['content'][1]['image_url']['url'], 'data:image/png;base64,')
        );
    }

    public function test_token_limited_image_analysis_is_not_reported_as_complete(): void
    {
        config(['services.groq.key' => 'test-key', 'services.groq.vision_model' => 'test-vision-model']);
        Http::fake(['api.groq.com/*' => Http::response([
            'choices' => [[
                'finish_reason' => 'length',
                'message' => ['content' => 'تظهر في الصورة أعداد تحتاج إلى جمع.'],
            ]],
        ])]);

        $response = app(NoorImageAnalysisController::class)
            ->analyze($this->request(UploadedFile::fake()->image('lesson.png', 100, 100)));

        $this->assertSame(200, $response->status());
        $this->assertTrue($response->getData(true)['incomplete']);
        $this->assertStringContainsString('أعد إرسال الصورة', $response->getData(true)['reply']);
    }
}
