<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SupportWriteActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        $category = $request->input('category', 'support');
        $subject = trim((string) $request->input('subject'));
        $message = trim((string) $request->input('message'));

        if (!in_array($category, self::CATEGORIES, true)) {
            return response()->json(['error' => 'التصنيف غير صالح'], 400);
        }
        if ($subject === '' || $message === '') {
            return response()->json(['error' => 'العنوان والرسالة مطلوبان'], 400);
        }

        try {
            $id = DB::table('support_tickets')->insertGetId([
                'user_id' => $user->id,
                'category' => $category,
                'subject' => $subject,
                'message' => $message,
            ]);

            return response()->json([
                'ticket' => DB::table('support_tickets')->find($id),
            ], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $ticket = DB::table('support_tickets')->where('id', $id)->first();
            if (!$ticket) {
                return response()->json(['error' => 'التذكرة غير موجودة'], 404);
            }

            $updates = ['updated_at' => now()];

            if ($request->has('status')) {
                $status = $request->input('status');
                if (!in_array($status, self::STATUSES, true)) {
                    return response()->json(['error' => 'الحالة غير صالحة'], 400);
                }
                $updates['status'] = $status;
            }

            $hasReply = false;
            if ($request->has('admin_reply')) {
                $reply = trim((string) $request->input('admin_reply'));
                $updates['admin_reply'] = $reply !== '' ? $reply : null;
                $hasReply = $reply !== '';
            }

            DB::table('support_tickets')->where('id', $id)->update($updates);

            Notify::toUser(
                $ticket->user_id,
                'تحديث على طلب الدعم',
                $hasReply
                    ? 'تم الرد على طلبك: ' . $ticket->subject
                    : 'تم تحديث حالة طلبك: ' . $ticket->subject,
                'support_update'
            );

            return response()->json([
                'ticket' => DB::table('support_tickets')->find($id),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function resolve(Request $request, $id)
    {
        $request->merge(['status' => 'resolved']);

        return $this->update($request, $id);
    }
}
