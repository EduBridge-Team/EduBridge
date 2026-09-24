<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait AccountProfileReadActions
{
    public function me(Request $request)
    {
        $jwtUser = $request->attributes->get('jwt_user');
        $userId = is_object($jwtUser) ? ($jwtUser->id ?? null) : null;

        if (!$userId) {
            return response()->json(['error' => 'تعذّر تحديد المستخدم الحالي'], 401);
        }

        $user = DB::table('users')->where('id', $userId)->first();
        if (!$user) {
            return response()->json(['error' => 'المستخدم غير موجود'], 404);
        }

        $profile = [
            'id' => $user->id,
            'name' => $user->name ?? null,
            'email' => $user->email ?? null,
            'role' => $user->role ?? ($jwtUser->role ?? null),
            'phone' => Schema::hasColumn('users', 'phone') ? ($user->phone ?? null) : null,
            'specialty' => Schema::hasColumn('users', 'specialty')
                ? ($user->specialty ?? null)
                : null,
            'verification_status' => Schema::hasColumn('users', 'verification_status')
                ? ($user->verification_status ?? 'pending')
                : 'pending',
            'created_at' => $user->created_at ?? null,
        ];

        if (Schema::hasColumn('users', 'avatar_url')) {
            $profile['avatar_url'] = $user->avatar_url ?? null;
        }

        $profile['is_verified'] =
            ($profile['verification_status'] ?? 'pending') === 'verified';

        return response()->json(['user' => $profile]);
    }
}
