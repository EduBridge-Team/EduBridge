<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CaseDiscussionMessageActions
{
    public function addMessage(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $discussion = DB::table('case_discussions')->where('id', $id)->first();

        if (!$discussion) {
            return response()->json(['error' => 'دراسة الحالة غير موجودة'], 404);
        }
        if (!$this->canAccess($user, $discussion)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }
        if ($discussion->status === 'resolved') {
            return response()->json(['error' => 'تم إغلاق هذه الدراسة'], 409);
        }

        $content = trim((string) $request->input('content', ''));
        $type = (string) $request->input('type', 'text');

        if ($content === '') {
            return response()->json(['error' => 'الرسالة مطلوبة'], 422);
        }
        if (!in_array($type, self::MESSAGE_TYPES, true)) {
            return response()->json(['error' => 'نوع الرسالة غير صالح'], 422);
        }

        $messageId = DB::table('case_discussion_messages')->insertGetId([
            'discussion_id' => $id,
            'sender_id' => $user->id,
            'content' => $content,
            'type' => $type,
            'attachments' => json_encode(
                $request->input('attachments', []),
                JSON_UNESCAPED_UNICODE
            ),
            'created_at' => now(),
        ]);

        DB::table('case_discussions')->where('id', $id)->update([
            'status' => 'inReview',
            'updated_at' => now(),
        ]);

        $participantIds = DB::table('case_discussion_participants')
            ->where('discussion_id', $id)
            ->where('user_id', '!=', $user->id)
            ->pluck('user_id');

        foreach ($participantIds as $participantId) {
            Notify::toUser(
                $participantId,
                'رسالة جديدة في دراسة حالة',
                $content,
                'case_discussion_message'
            );
        }

        $message = $this->messageRows((int) $id)->firstWhere('id', $messageId);

        return response()->json(['message' => $message], 201);
    }
}
