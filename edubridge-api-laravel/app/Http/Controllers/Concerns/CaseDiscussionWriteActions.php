<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CaseDiscussionWriteActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['teacher','specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        $topic = trim((string) $request->input('topic', ''));
        $participants = $request->input('participant_ids', []);

        if ($childId <= 0 || $topic === '') {
            return response()->json(['error' => 'الطفل وموضوع الدراسة مطلوبان'], 422);
        }
        if (!$this->canAccessChild($user, $childId)) {
            return response()->json(['error' => 'لا تملك صلاحية إنشاء دراسة لهذا الطفل'], 403);
        }
        if (!is_array($participants) || !$participants) {
            return response()->json(['error' => 'اختر مشاركاً واحداً على الأقل'], 422);
        }

        $participants = array_values(array_unique(array_filter(array_map('intval', $participants))));
        $validUsers = DB::table('users')
            ->whereIn('id', $participants)
            ->whereIn('role', ['teacher','specialist'])
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->all();

        if (count($validUsers) !== count($participants)) {
            return response()->json(['error' => 'أحد المشاركين غير صالح'], 422);
        }

        if ($user->role !== 'admin') {
            $careTeamIds = $this->careTeamUserIds($childId);
            $outsideTeam = array_diff($participants, $careTeamIds);
            if ($outsideTeam) {
                return response()->json(['error' => 'يمكن دعوة أعضاء فريق الطفل فقط'], 403);
            }
        }

        try {
            $id = DB::transaction(function () use ($request, $user, $childId, $topic, $participants) {
                $id = DB::table('case_discussions')->insertGetId([
                    'child_id' => $childId,
                    'topic' => $topic,
                    'description' => $request->input('description'),
                    'status' => 'open',
                    'created_by_id' => $user->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                foreach ($participants as $participantId) {
                    DB::table('case_discussion_participants')->insert([
                        'discussion_id' => $id,
                        'user_id' => $participantId,
                        'created_at' => now(),
                    ]);
                }

                return $id;
            });

            foreach ($participants as $participantId) {
                Notify::toUser(
                    $participantId,
                    'دراسة حالة جديدة',
                    'تمت دعوتك للمشاركة في دراسة حالة: ' . $topic,
                    'case_discussion_created'
                );
            }

            $row = $this->baseQuery()->where('d.id', $id)->first();

            return response()->json(['discussion' => $this->hydrate($row)], 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر إنشاء دراسة الحالة'], 500);
        }
    }

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
            'attachments' => json_encode($request->input('attachments', []), JSON_UNESCAPED_UNICODE),
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

    public function resolve(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $discussion = DB::table('case_discussions')->where('id', $id)->first();

        if (!$discussion) {
            return response()->json(['error' => 'دراسة الحالة غير موجودة'], 404);
        }
        if (!$this->canAccess($user, $discussion)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::table('case_discussions')->where('id', $id)->update([
            'status' => 'resolved',
            'resolved_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['ok' => true]);
    }
}
