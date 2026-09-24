<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConversationWriteActions
{
    public function store(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $myId = (int) ($me->id ?? 0);
        $validated = $request->validate([
            'other_user_id' => ['required', 'integer'],
            'subject' => ['nullable', 'string', 'max:150'],
        ]);
        $otherId = (int) $validated['other_user_id'];

        if ($myId === $otherId) {
            return response()->json(['error' => 'لا يمكنك بدء محادثة مع نفسك'], 422);
        }

        $other = DB::table('users')->select('id', 'name', 'role')->find($otherId);
        if (!$other) {
            return response()->json(['error' => 'المستخدم غير موجود'], 404);
        }
        if (!$this->canCommunicate((string) ($me->role ?? ''), (string) $other->role)) {
            return response()->json(['error' => 'لا تملك صلاحية التواصل مع هذا المستخدم'], 403);
        }

        $firstId = min($myId, $otherId);
        $secondId = max($myId, $otherId);

        try {
            $conversation = DB::transaction(function () use ($firstId, $secondId, $myId, $other, $validated) {
                $existing = DB::table('conversations')
                    ->where('participant_one_id', $firstId)
                    ->where('participant_two_id', $secondId)
                    ->first();

                if ($existing) {
                    return $existing;
                }

                $now = now();
                $id = DB::table('conversations')->insertGetId([
                    'participant_one_id' => $firstId,
                    'participant_two_id' => $secondId,
                    'created_by_id' => $myId,
                    'subject' => trim((string) ($validated['subject'] ?? '')) ?: 'محادثة مع ' . $other->name,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);

                return DB::table('conversations')->find($id);
            });

            return response()->json(['conversation' => $conversation], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إنشاء المحادثة'], 500);
        }
    }

    public function send(Request $request, $conversationId)
    {
        $me = $request->attributes->get('jwt_user');
        $myId = (int) ($me->id ?? 0);
        $conversation = $this->conversationForUser((int) $conversationId, $myId);
        if (!$conversation) {
            return response()->json(['error' => 'المحادثة غير موجودة'], 404);
        }

        $validated = $request->validate([
            'content' => ['nullable', 'string', 'max:4000', 'required_without:file_url'],
            'file_url' => ['nullable', 'string', 'max:2048', 'required_without:content'],
        ]);
        $content = trim((string) ($validated['content'] ?? ''));
        $fileUrl = trim((string) ($validated['file_url'] ?? ''));

        if ($content === '' && $fileUrl === '') {
            return response()->json(['error' => 'الرسالة فارغة'], 422);
        }

        try {
            $message = DB::transaction(function () use ($conversation, $myId, $content, $fileUrl) {
                $now = now();
                $id = DB::table('conversation_messages')->insertGetId([
                    'conversation_id' => $conversation->id,
                    'sender_id' => $myId,
                    'content' => $content !== '' ? $content : null,
                    'file_url' => $fileUrl !== '' ? $fileUrl : null,
                    'created_at' => $now,
                ]);

                DB::table('conversations')
                    ->where('id', $conversation->id)
                    ->update(['updated_at' => $now]);

                return DB::table('conversation_messages')->find($id);
            });

            $recipientId = (int) $conversation->participant_one_id === $myId
                ? (int) $conversation->participant_two_id
                : (int) $conversation->participant_one_id;

            Notify::toUser(
                $recipientId,
                'رسالة جديدة',
                $content !== '' ? mb_strimwidth($content, 0, 120, '…') : 'أرسل لك مرفقاً جديداً',
                'conversation_message'
            );

            $message->is_mine = true;
            return response()->json(['message' => $message], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إرسال الرسالة'], 500);
        }
    }
}
