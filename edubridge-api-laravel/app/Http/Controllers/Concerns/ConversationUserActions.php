<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConversationUserActions
{
    public function users(Request $request)
    {
        $me = $request->attributes->get('jwt_user');
        $myId = (int) ($me->id ?? 0);
        $myRole = (string) ($me->role ?? '');

        try {
            $users = DB::table('users')
                ->where('id', '!=', $myId)
                ->select('id', 'name', 'email', 'role')
                ->orderBy('name')
                ->get()
                ->filter(fn ($user) => $this->canCommunicate($myRole, (string) $user->role))
                ->values();

            return response()->json(['users' => $users]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'تعذّر تحميل جهات الاتصال'], 500);
        }
    }
}
