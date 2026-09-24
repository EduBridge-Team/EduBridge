<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SessionCompleteActions
{
    public function complete(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $session = DB::table('sessions')->where('id', $id)->first();

        if (!$session) {
            return response()->json(['error' => 'اجتماع الدعم غير موجود'], 404);
        }
        if (!$this->canAccess($user, $session) || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }
        if (($session->status ?? null) === 'cancelled') {
            return response()->json(['error' => 'لا يمكن إنهاء جلسة ملغية'], 409);
        }

        $mood = $request->input('mood_rating');
        if ($mood !== null && ((int) $mood < 1 || (int) $mood > 5)) {
            return response()->json([
                'error' => 'تقييم المشاركة التعليمية يجب أن يكون بين 1 و5',
            ], 422);
        }

        $tags = $request->input('tags', []);
        if ($tags !== null && !is_array($tags)) {
            return response()->json(['error' => 'الوسوم يجب أن تكون قائمة'], 422);
        }

        try {
            DB::transaction(function () use ($request, $id, $session, $mood, $tags) {
                DB::table('sessions')->where('id', $id)->update([
                    'status' => 'done',
                    'completed_at' => now(),
                    'notes' => $request->input('notes'),
                    'recommendations' => $request->input('recommendations'),
                    'mood_rating' => $mood !== null ? (int) $mood : null,
                    'tags' => json_encode($tags ?? [], JSON_UNESCAPED_UNICODE),
                ]);

                if (!empty($session->learning_support_request_id)) {
                    DB::table('learning_support_requests')
                        ->where('id', $session->learning_support_request_id)
                        ->update([
                            'status' => 'completed',
                            'completed_at' => now(),
                            'updated_at' => now(),
                        ]);
                }
            });

            Notify::toChildParents(
                $session->child_id,
                'اكتملت جلسة الدعم التعليمي',
                'تم تسجيل جلسة الدعم التعليمي كمكتملة.',
                'learning_support_meeting_completed'
            );

            $fresh = $this->baseQuery()->where('s.id', $id)->first();

            return response()->json([
                'session' => $this->normalizeSession($fresh),
            ]);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر إنهاء الجلسة'], 500);
        }
    }
}
