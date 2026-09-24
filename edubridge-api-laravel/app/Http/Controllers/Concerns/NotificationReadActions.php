<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait NotificationReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = DB::table('notifications')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->select(
                    'id',
                    'user_id',
                    'title',
                    'message',
                    'message as body',
                    'type',
                    'is_read',
                    'created_at'
                );

            if ($request->query('unread')) {
                $query->where('is_read', false);
            }

            return response()->json(['notifications' => $query->get()]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function unreadCount(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $count = DB::table('notifications')
                ->where('user_id', $user->id)
                ->where('is_read', false)
                ->count();

            return response()->json(['count' => $count]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
