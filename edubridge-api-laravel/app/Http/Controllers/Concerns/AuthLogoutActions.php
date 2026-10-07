<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait AuthLogoutActions
{
    public function logout(Request $request)
    {
        $account = $request->attributes->get('jwt_user');

        DB::table('users')
            ->where('id', (int) $account->id)
            ->increment('session_version');

        return response()->json(['message' => 'تم تسجيل الخروج']);
    }
}
