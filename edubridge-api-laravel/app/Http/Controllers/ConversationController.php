<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConversationController extends Controller
{
    private const STAFF_ROLES = ['teacher', 'specialist', 'admin', 'ministry', 'institution'];

    // GET /api/conversations
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

    // POST /api/conversations
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

            // يعيد 201 أيضاً عند إعادة استخدام المحادثة حتى يبقى متوافقاً مع التطبيق الحالي.
            return response()->json(['conversation' => $conversation], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إنشاء المحادثة'], 500);
        }
    }

    // GET /api/conversations/{conversation}/messages
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
                ->select('m.id', 'm.conversation_id', 'm.sender_id', 'm.content',
                    'm.file_url', 'm.created_at', 'u.name as sender_name', 'u.role as sender_role')
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

    // POST /api/conversations/{conversation}/messages
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
                DB::table('conversations')->where('id', $conversation->id)->update(['updated_at' => $now]);
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

    private function conversationForUser(int $conversationId, int $userId): ?object
    {
        return DB::table('conversations')
            ->where('id', $conversationId)
            ->where(function ($query) use ($userId) {
                $query->where('participant_one_id', $userId)
                    ->orWhere('participant_two_id', $userId);
            })
            ->first();
    }

    private function canCommunicate(string $fromRole, string $toRole): bool
    {
        if ($fromRole === 'parent') {
            return in_array($toRole, ['teacher', 'specialist', 'admin'], true);
        }
        if ($toRole === 'parent') {
            return in_array($fromRole, ['teacher', 'specialist', 'admin'], true);
        }
        return in_array($fromRole, self::STAFF_ROLES, true)
            && in_array($toRole, self::STAFF_ROLES, true);
    }
}
