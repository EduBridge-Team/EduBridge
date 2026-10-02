<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

final class EngagementEvent
{
    public static function run(int $childId, int $userId, ?string $eventId, array $payload, callable $work): array
    {
        if ($eventId !== null && !preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i', $eventId)) {
            abort(422, 'Invalid event_id');
        }
        $eventId = $eventId === null ? null : strtolower($eventId);
        $hash = hash('sha256', json_encode($payload));
        return DB::transaction(function () use ($childId, $userId, $eventId, $hash, $work) {
            // A parent row exists even before the first reward. Lock it to serialize concurrent first writes.
            if (!DB::table('children')->where('id', $childId)->lockForUpdate()->first()) abort(404);
            if ($eventId !== null) {
                $previous = DB::table('engagement_events')->where('child_id', $childId)
                    ->where('user_id', $userId)->where('event_id', $eventId)->first();
                if ($previous) {
                    if (!hash_equals($previous->request_hash, $hash)) abort(409, 'Event ID already used for different input');
                    return json_decode($previous->response, true, flags: JSON_THROW_ON_ERROR);
                }
            }
            $result = $work();
            if ($eventId !== null) DB::table('engagement_events')->insert([
                'child_id' => $childId, 'user_id' => $userId, 'event_id' => $eventId,
                'request_hash' => $hash, 'response' => json_encode($result, JSON_THROW_ON_ERROR), 'created_at' => now(),
            ]);
            return $result;
        });
    }
}
