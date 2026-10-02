<?php

namespace App\Http\Controllers;

use App\Support\ChildAccess;
use App\Support\EngagementEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EngagementController extends Controller
{
    public function summary(Request $request, $childId)
    {
        $me = $request->attributes->get('jwt_user');
        $childId = (int) $childId;

        if (!ChildAccess::allowed($me, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $stars = (int) (DB::table('child_rewards')->where('child_id', $childId)->value('stars') ?? 0);
        $attempts = DB::table('game_attempts')->where('child_id', $childId);

        return response()->json([
            'stars' => $stars,
            'game_attempts_count' => (clone $attempts)->count(),
            'average_game_score' => (int) round((float) ((clone $attempts)->avg('score') ?? 0)),
            'recent_attempts' => (clone $attempts)
                ->orderByDesc('created_at')
                ->limit(20)
                ->get(),
        ]);
    }

    public function addStars(Request $request, $childId)
    {
        $me = $request->attributes->get('jwt_user');
        $childId = (int) $childId;

        if (!ChildAccess::allowed($me, $childId) || $me->role === 'ministry') {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $request->validate(['event_id' => 'nullable|uuid']);
        $count = (int) $request->input('count', 1);
        if ($count < 1 || $count > 20) {
            return response()->json(['error' => 'عدد النجوم غير صالح'], 422);
        }

        $result = EngagementEvent::run($childId, (int) $me->id, $request->input('event_id'), ['kind' => 'stars', 'count' => $count], function () use ($childId, $count) {
            $row = DB::table('child_rewards')->where('child_id', $childId)->lockForUpdate()->first();
            if (!$row) {
                DB::table('child_rewards')->insert([
                    'child_id' => $childId,
                    'stars' => $count,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                return ['stars' => $count];
            }

            $next = (int) $row->stars + $count;
            DB::table('child_rewards')->where('child_id', $childId)->update([
                'stars' => $next,
                'updated_at' => now(),
            ]);
            return ['stars' => $next];
        });

        return response()->json($result);
    }

    public function storeAttempt(Request $request, $childId)
    {
        $me = $request->attributes->get('jwt_user');
        $childId = (int) $childId;

        if (!ChildAccess::allowed($me, $childId) || $me->role === 'ministry') {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $request->validate(['event_id' => 'nullable|uuid']);
        $gameKey = trim((string) $request->input('game_key', ''));
        $score = (int) $request->input('score', -1);
        $duration = $request->input('duration_seconds');

        if ($gameKey === '' || mb_strlen($gameKey) > 80) {
            return response()->json(['error' => 'معرّف اللعبة غير صالح'], 422);
        }
        if ($score < 0 || $score > 100) {
            return response()->json(['error' => 'النتيجة يجب أن تكون بين 0 و100'], 422);
        }
        if ($duration !== null && ((int) $duration < 0 || (int) $duration > 86400)) {
            return response()->json(['error' => 'مدة اللعب غير صالحة'], 422);
        }

        $starsEarned = $score >= 90 ? 3 : ($score >= 70 ? 2 : ($score >= 50 ? 1 : 0));

        $result = EngagementEvent::run($childId, (int) $me->id, $request->input('event_id'), [
            'kind' => 'game', 'game_key' => $gameKey, 'score' => $score,
            'duration_seconds' => $duration === null ? null : (int) $duration,
        ], function () use ($childId, $me, $gameKey, $score, $starsEarned, $duration) {
            $attemptId = DB::table('game_attempts')->insertGetId([
                'child_id' => $childId,
                'user_id' => $me->id,
                'game_key' => $gameKey,
                'score' => $score,
                'stars_earned' => $starsEarned,
                'duration_seconds' => $duration === null ? null : (int) $duration,
                'created_at' => now(),
            ]);

            $row = DB::table('child_rewards')->where('child_id', $childId)->lockForUpdate()->first();
            $stars = (int) ($row->stars ?? 0) + $starsEarned;

            if ($row) {
                DB::table('child_rewards')->where('child_id', $childId)->update([
                    'stars' => $stars,
                    'updated_at' => now(),
                ]);
            } else {
                DB::table('child_rewards')->insert([
                    'child_id' => $childId,
                    'stars' => $stars,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            return [
                'attempt' => DB::table('game_attempts')->find($attemptId),
                'stars' => $stars,
            ];
        });

        return response()->json($result, 201);
    }
}
