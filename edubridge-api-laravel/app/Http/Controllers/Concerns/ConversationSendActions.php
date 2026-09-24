<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConversationSendActions
{
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
                $content !== ''
                    ? mb_strimwidth($content, 0, 120, '…')
                    : 'أرسل لك مرفقاً جديداً',
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
