<?php

namespace App\Http\Controllers;

// الإشعارات — لكل مستخدم إشعاراته
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    // إشعارات المستخدم الحالي (مع فلترة اختيارية لغير المقروء)
    // GET /api/notifications?unread=1
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = DB::table('notifications')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at');

            if ($request->query('unread')) {
                $query->where('is_read', false);
            }

            return response()->json(['notifications' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // إرسال إشعار لمستخدم (معلّم / مختص / أدمن)
    // POST /api/notifications   body: { user_id, message }
    public function store(Request $request)
    {
        $userId = $request->input('user_id');
        $message = $request->input('message');

        if (!$userId || !$message) {
            return response()->json(['error' => 'user_id و message مطلوبان'], 400);
        }

        try {
            if (!DB::table('users')->where('id', $userId)->exists()) {
                return response()->json(['error' => 'المستخدم غير موجود'], 404);
            }

            $id = DB::table('notifications')->insertGetId([
                'user_id' => $userId,
                'message' => $message,
            ]);

            return response()->json(['notification' => DB::table('notifications')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تعليم إشعار كمقروء (لصاحبه فقط)
    // PUT /api/notifications/:id/read
    public function markRead(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $notif = DB::table('notifications')->where('id', $id)->first();
            if (!$notif) {
                return response()->json(['error' => 'الإشعار غير موجود'], 404);
            }
            if ((int) $notif->user_id !== (int) $user->id) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            DB::table('notifications')->where('id', $id)->update(['is_read' => true]);
            return response()->json(['notification' => DB::table('notifications')->find($id)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تعليم كل إشعارات المستخدم كمقروءة
    // PUT /api/notifications/read-all
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
