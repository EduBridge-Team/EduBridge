<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConversationCreateActions
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
                    'subject' => trim((string) ($validated['subject'] ?? ''))
                        ?: 'محادثة مع ' . $other->name,
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
}
