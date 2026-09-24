<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

trait AssistantChatAction
{
    public function chat(Request $request)
    {
        $validated = $request->validate([
            'messages' => ['required', 'array', 'min:1', 'max:12'],
            'messages.*.role' => ['required', 'in:user,assistant'],
            'messages.*.content' => ['required', 'string', 'max:2000'],
            'context' => ['nullable', 'string', 'max:1200'],
        ]);

        $apiKey = config('services.groq.key');
        if (!$apiKey) {
            return response()->json([
                'error' => 'مساعد نور غير مفعّل على الخادم بعد.',
            ], 503);
        }

        $jwtUser = $request->attributes->get('jwt_user');
        $role = $jwtUser->role ?? 'user';
        $roleName = [
            'parent' => 'ولي أمر',
            'teacher' => 'معلّم',
            'specialist' => 'مختص',
            'admin' => 'مسؤول',
            'ministry' => 'موظف وزارة',
            'institution' => 'موظف مؤسسة',
        ][$role] ?? 'مستخدم';

        $context = trim((string) ($validated['context'] ?? ''));
        $instructions = $this->assistantInstructions($roleName, $context);

        $messages = collect($validated['messages']);
        if (!$messages->contains('role', 'user')) {
            return response()->json(['error' => 'يجب إرسال سؤال للمساعد.'], 422);
        }

        $transcript = $messages
            ->map(function (array $message): string {
                $speaker = $message['role'] === 'assistant' ? 'نور' : 'المستخدم';

                return $speaker . ': ' . $this->redactPersonalData(trim($message['content']));
            })
            ->implode("\n");

        try {
            $response = Http::withToken($apiKey)
                ->acceptJson()
                ->timeout(35)
                ->post('https://api.groq.com/openai/v1/chat/completions', [
                    'model' => config('services.groq.model'),
                    'messages' => [
                        [
                            'role' => 'system',
                            'content' => $instructions,
                        ],
                        [
                            'role' => 'user',
                            'content' => $transcript,
                        ],
                    ],
                    'max_completion_tokens' => 500,
                ]);
        } catch (ConnectionException $e) {
            report($e);

            return response()->json(['error' => 'تعذّر الاتصال بالمساعد الآن.'], 502);
        }

        if (!$response->successful()) {
            Log::warning('Groq assistant request failed', [
                'status' => $response->status(),
            ]);

            $status = $response->status() === 429 ? 429 : 502;
            $message = $status === 429
                ? 'نور مشغول قليلاً. حاول مجدداً بعد لحظة.'
                : 'تعذّر الحصول على رد من نور الآن.';

            return response()->json(['error' => $message], $status);
        }

        $payload = $response->json();
        $reply = is_array($payload) ? $this->extractOutputText($payload) : null;
        if ($reply === null) {
            return response()->json(['error' => 'وصل رد غير مكتمل من المساعد.'], 502);
        }

        return response()->json(['reply' => $reply]);
    }
}
