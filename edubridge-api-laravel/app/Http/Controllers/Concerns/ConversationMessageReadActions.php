<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConversationMessageReadActions
{
    public function messages(Request $request, $conversationId)
    {
        $me = $request->attributes->get('jwt_user');
        $myId = (int) ($me->id ?? 0);
        $conversation = $this->conversationForUser((int) $conversationId, $myId);

        if (!$conversation) {
            return response()->json(['error' => 'المحادثة غير موجودة'], 404);
        }

        try {
            $messages = DB::table('conversation_messages as m')
                ->leftJoin('users as u', 'u.id', '=', 'm.sender_id')
                ->where('m.conversation_id', $conversation->id)
                ->orderBy('m.id')
                ->select(
                    'm.id',
                    'm.conversation_id',
                    'm.sender_id',
                    'm.content',
                    'm.file_url',
                    'm.created_at',
                    'u.name as sender_name',
                    'u.role as sender_role'
                )
                ->get()
                ->map(function ($message) use ($myId) {
                    $message->is_mine = (int) $message->sender_id === $myId;

                    return $message;
                });

            return response()->json(['messages' => $messages]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'تعذّر تحميل الرسائل'], 500);
        }
    }
}
