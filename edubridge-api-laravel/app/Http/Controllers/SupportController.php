<?php

namespace App\Http\Controllers;

// الدعم الفني والشكاوى (البطاقة 11)
// المستخدم ينشئ تذكرة/شكوى ويتابعها؛ الأدمن يستعرض الكل ويرد ويغيّر الحالة.
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;

class SupportController extends Controller
{
    private const CATEGORIES = ['support', 'complaint'];
    private const STATUSES = ['open', 'in_progress', 'resolved', 'closed'];

    // إنشاء تذكرة دعم / شكوى
    // POST /api/support   body: { category, subject, message }
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

            return response()->json(['ticket' => DB::table('support_tickets')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // قائمة التذاكر
    // - الأدمن: كل التذاكر (مع فلترة اختيارية ?status= أو ?category=)
    // - غيره: تذاكره فقط
    // GET /api/support
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = DB::table('support_tickets as t')
                ->leftJoin('users as u', 'u.id', '=', 't.user_id')
                ->select('t.*', 'u.name as user_name', 'u.email as user_email', 'u.role as user_role')
                ->orderByDesc('t.created_at');

            if ($user->role === 'admin') {
                if ($request->query('status')) {
                    $query->where('t.status', $request->query('status'));
                }
                if ($request->query('category')) {
                    $query->where('t.category', $request->query('category'));
                }
            } else {
                $query->where('t.user_id', $user->id);
            }

            return response()->json(['tickets' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // رد الأدمن على التذكرة و/أو تغيير حالتها
    // PUT /api/support/:id   body: { status?, admin_reply? }   (أدمن)
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

            // إشعار صاحب التذكرة عند الرد أو تغيّر الحالة
            Notify::toUser(
                $ticket->user_id,
                'تحديث على طلب الدعم',
                $hasReply
                    ? 'تم الرد على طلبك: ' . $ticket->subject
                    : 'تم تحديث حالة طلبك: ' . $ticket->subject,
                'support_update'
            );

            return response()->json(['ticket' => DB::table('support_tickets')->find($id)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
