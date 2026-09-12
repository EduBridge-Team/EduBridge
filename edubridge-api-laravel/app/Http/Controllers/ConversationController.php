<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConversationController extends Controller
{
    public function users(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $users = DB::table('users')
            ->where('id', '!=', $me->id)
            ->select('id', 'name', 'role')
            ->orderBy('name')
            ->get();

        return response()->json(['users' => $users]);
    }

    public function index(Request $request)
    {
        $me = (int) $request->attributes->get('jwt_user')->id;
        $rows = DB::table('conversations as c')
            ->where(fn ($query) => $query->where('c.participant_one_id', $me)->orWhere('c.participant_two_id', $me))
            ->leftJoin('conversation_messages as m', 'm.id', '=', DB::raw('(SELECT cm.id FROM conversation_messages cm WHERE cm.conversation_id = c.id ORDER BY cm.id DESC LIMIT 1)'))
            ->join('users as u', function ($join) use ($me) {
                $join->on('u.id', '=', DB::raw("CASE WHEN c.participant_one_id = {$me} THEN c.participant_two_id ELSE c.participant_one_id END"));
            })
            ->select('c.id', 'c.subject', 'u.id as other_user_id', 'u.name as other_user_name',
                'u.role as other_user_role', 'm.content as last_message', 'm.created_at as last_message_at')
            ->orderByRaw('COALESCE(m.created_at, c.created_at) DESC')
            ->get();

        return response()->json(['conversations' => $rows]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'other_user_id' => ['required', 'integer', 'exists:users,id'],
            'subject' => ['nullable', 'string', 'max:255'],
        ]);
        $me = (int) $request->attributes->get('jwt_user')->id;
        $other = (int) $validated['other_user_id'];
        if ($me === $other) return response()->json(['error' => 'لا يمكن إنشاء محادثة مع نفسك'], 422);

        [$one, $two] = $me < $other ? [$me, $other] : [$other, $me];
        $existing = DB::table('conversations')
            ->where('participant_one_id', $one)->where('participant_two_id', $two)->first();
        if ($existing) return response()->json(['conversation' => $existing]);

        $now = now();
        $id = DB::table('conversations')->insertGetId([
            'participant_one_id' => $one,
            'participant_two_id' => $two,
            'subject' => $validated['subject'] ?? null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
        return response()->json(['conversation' => DB::table('conversations')->find($id)], 201);
    }

    public function messages(Request $request, int $id)
    {
        $me = (int) $request->attributes->get('jwt_user')->id;
        $this->authorizeParticipant($id, $me);
        $messages = DB::table('conversation_messages as m')
            ->join('users as u', 'u.id', '=', 'm.sender_id')
            ->where('m.conversation_id', $id)
            ->select('m.id', 'm.content', 'm.file_url', 'm.sender_id', 'u.name as sender_name', 'm.created_at')
            ->orderBy('m.id')
            ->get()
            ->map(function ($message) use ($me) {
                $message->is_mine = (int) $message->sender_id === $me;
                return $message;
            });
        return response()->json(['messages' => $messages]);
    }

    public function send(Request $request, int $id)
    {
        $validated = $request->validate([
            'content' => ['required', 'string', 'max:4000'],
            'file_url' => ['nullable', 'string', 'max:1000'],
        ]);
        $me = (int) $request->attributes->get('jwt_user')->id;
        $this->authorizeParticipant($id, $me);
        $now = now();
        $messageId = DB::table('conversation_messages')->insertGetId([
            'conversation_id' => $id,
            'sender_id' => $me,
            'content' => trim($validated['content']),
            'file_url' => $validated['file_url'] ?? null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
        DB::table('conversations')->where('id', $id)->update(['updated_at' => $now]);
        return response()->json(['message' => DB::table('conversation_messages')->find($messageId)], 201);
    }

    private function authorizeParticipant(int $conversationId, int $userId): void
    {
        $allowed = DB::table('conversations')->where('id', $conversationId)
            ->where(fn ($query) => $query->where('participant_one_id', $userId)->orWhere('participant_two_id', $userId))
            ->exists();
        abort_unless($allowed, 404, 'المحادثة غير موجودة');
    }
}
