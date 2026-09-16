<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChildAccessibilityProfileController extends Controller
{
    private function canAccessChild(int $userId, string $role, int $childId): bool
    {
        if (in_array($role, ['admin', 'teacher', 'specialist'], true)) {
            return DB::table('children')->where('id', $childId)->exists();
        }

        if ($role === 'parent') {
            return DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $userId)
                ->exists();
        }

        return false;
    }

    public function show(Request $request, int $childId)
    {
        $jwtUser = $request->attributes->get('jwt_user');
        $userId = (int) ($jwtUser->id ?? 0);
        $role = (string) ($jwtUser->role ?? '');

        if (!$this->canAccessChild($userId, $role, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $row = DB::table('child_accessibility_profiles')
            ->where('child_id', $childId)
            ->first();

        if (!$row) {
            return response()->json(['profile' => null]);
        }

        $profile = is_string($row->profile)
            ? json_decode($row->profile, true)
            : $row->profile;

        return response()->json([
            'profile' => $profile,
            'updated_at' => $row->updated_at,
        ]);
    }

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
