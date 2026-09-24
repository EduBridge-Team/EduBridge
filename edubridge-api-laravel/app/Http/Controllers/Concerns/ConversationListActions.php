<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConversationListActions
{
    public function index(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $myId = (int) ($me->id ?? 0);

        try {
            $conversations = DB::table('conversations')
                ->where(function ($query) use ($myId) {
                    $query->where('participant_one_id', $myId)
                        ->orWhere('participant_two_id', $myId);
                })
                ->orderByDesc('updated_at')
                ->limit(100)
                ->get();

            $otherIds = $conversations->map(
                fn ($conversation) => (int) $conversation->participant_one_id === $myId
                    ? (int) $conversation->participant_two_id
                    : (int) $conversation->participant_one_id
            )->unique()->values();

            $users = DB::table('users')
                ->whereIn('id', $otherIds)
                ->select('id', 'name', 'role')
                ->get()
                ->keyBy('id');

            $conversationIds = $conversations->pluck('id');
            $lastMessageIds = DB::table('conversation_messages')
                ->whereIn('conversation_id', $conversationIds)
                ->selectRaw('MAX(id) AS id')
                ->groupBy('conversation_id')
                ->pluck('id');

            $lastMessages = DB::table('conversation_messages')
                ->whereIn('id', $lastMessageIds)
                ->get()
                ->keyBy('conversation_id');

            $result = $conversations->map(function ($conversation) use ($myId, $users, $lastMessages) {
                $otherId = (int) $conversation->participant_one_id === $myId
                    ? (int) $conversation->participant_two_id
                    : (int) $conversation->participant_one_id;
                $other = $users->get($otherId);
                $last = $lastMessages->get($conversation->id);

                return [
                    'id' => $conversation->id,
                    'subject' => $conversation->subject,
                    'other_user_id' => $otherId,
                    'other_user_name' => $other->name ?? 'مستخدم',
                    'other_user_role' => $other->role ?? '',
                    'last_message' => $last?->content ?: ($last?->file_url ? '📎 مرفق' : ''),
                    'last_message_at' => $last?->created_at,
                    'created_at' => $conversation->created_at,
                    'updated_at' => $conversation->updated_at,
                ];
            });

            return response()->json(['conversations' => $result]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'تعذّر تحميل المحادثات'], 500);
        }
    }
}
