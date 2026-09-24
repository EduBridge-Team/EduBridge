<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildAccessibilityProfileReadActions
{
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
}
