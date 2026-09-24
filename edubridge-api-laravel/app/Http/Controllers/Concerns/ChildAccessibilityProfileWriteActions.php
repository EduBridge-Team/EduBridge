<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildAccessibilityProfileWriteActions
{
    public function update(Request $request, int $childId)
    {
        $jwtUser = $request->attributes->get('jwt_user');
        $userId = (int) ($jwtUser->id ?? 0);
        $role = (string) ($jwtUser->role ?? '');

        if (!$this->canAccessChild($userId, $role, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $data = $request->validate([
            'profile' => 'required|array',
        ]);

        $payload = [
            'profile' => json_encode($data['profile'], JSON_UNESCAPED_UNICODE),
            'updated_by' => $userId,
            'updated_at' => now(),
        ];

        $existing = DB::table('child_accessibility_profiles')
            ->where('child_id', $childId)
            ->exists();

        DB::table('child_accessibility_profiles')->updateOrInsert(
            ['child_id' => $childId],
            $existing ? $payload : array_merge($payload, ['created_at' => now()])
        );

        return response()->json([
            'profile' => $data['profile'],
            'message' => 'تم حفظ إعدادات التكييف',
        ]);
    }
}
