<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use App\Support\Notify;
use Illuminate\Support\Facades\DB;

trait NotificationWriteActions
{
    public function send(Request $request)
    {
        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'title' => ['required', 'string', 'max:150'],
            'body' => ['required', 'string', 'max:255'],
            'type' => ['nullable', 'string', 'max:40'],
        ]);

        Notify::toUser(
            (int) $data['user_id'],
            $data['title'],
            $data['body'],
            $data['type'] ?? null,
        );

        return response()->json(['message' => 'تم إرسال الإشعار'], 201);
    }

    public function markRead(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $notification = DB::table('notifications')->where('id', $id)->first();
            if (!$notification) {
                return response()->json(['error' => 'الإشعار غير موجود'], 404);
            }
            if ((int) $notification->user_id !== (int) $user->id) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            DB::table('notifications')->where('id', $id)->update(['is_read' => true]);

            return response()->json([
                'notification' => DB::table('notifications')->find($id),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function markAllRead(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $count = DB::table('notifications')
                ->where('user_id', $user->id)
                ->where('is_read', false)
                ->update(['is_read' => true]);

            return response()->json(['message' => 'تم', 'count' => $count]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
