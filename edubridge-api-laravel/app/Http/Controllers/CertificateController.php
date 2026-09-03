<?php

namespace App\Http\Controllers;

// شهادات المعلّم/المختص لإثبات الأهلية (البطاقة 9)
// المعلّم/المختص يرفع شهاداته؛ الأدمن يعتمدها/يرفضها.
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;

class CertificateController extends Controller
{
    // شهادات المستخدم الحالي؛ والأدمن يرى الكل (أو مستخدم محدّد عبر ?user_id=،
    // مع فلترة اختيارية ?status=pending) لمراجعتها — البطاقة 9
    // GET /api/certificates
    public function index(Request $request)
    {
        $me = $request->attributes->get('jwt_user');

        try {
            if ($me->role === 'admin') {
                $query = DB::table('certificates as c')
                    ->leftJoin('users as u', 'u.id', '=', 'c.user_id')
                    ->select('c.*', 'u.name as user_name', 'u.email as user_email', 'u.role as user_role')
                    ->orderByDesc('c.created_at');

                if ($request->query('user_id')) {
                    $query->where('c.user_id', $request->query('user_id'));
                }
                if ($request->query('status')) {
                    $query->where('c.status', $request->query('status'));
                }
            } else {
                $query = DB::table('certificates')
                    ->where('user_id', $me->id)
                    ->orderByDesc('created_at');
            }

            return response()->json(['certificates' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // رفع شهادة جديدة (معلّم/مختص)
    // POST /api/certificates   body: { title, url }
    public function store(Request $request)
    {
        $me = $request->attributes->get('jwt_user');

        $title = trim((string) $request->input('title'));
        $url = trim((string) $request->input('url'));
        if ($title === '' || $url === '') {
            return response()->json(['error' => 'عنوان الشهادة ورابط الملف مطلوبان'], 400);
        }

        try {
            $id = DB::table('certificates')->insertGetId([
                'user_id' => $me->id,
                'title' => $title,
                'url' => $url,
            ]);

            return response()->json(['certificate' => DB::table('certificates')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // اعتماد/رفض شهادة (أدمن)
    // PUT /api/certificates/:id   body: { status, note? }
    public function review(Request $request, $id)
    {
        $status = $request->input('status');
        if (!in_array($status, ['verified', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون verified أو rejected'], 400);
        }

        try {
            $cert = DB::table('certificates')->where('id', $id)->first();
            if (!$cert) {
                return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            }

            DB::table('certificates')->where('id', $id)->update([
                'status' => $status,
                'note' => $request->input('note'),
            ]);

            Notify::toUser(
                $cert->user_id,
                $status === 'verified' ? 'تم اعتماد شهادتك' : 'تم رفض شهادتك',
                ($status === 'verified' ? 'تم اعتماد الشهادة: ' : 'تم رفض الشهادة: ') . $cert->title,
                'certificate'
            );

            return response()->json(['certificate' => DB::table('certificates')->find($id)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // حذف شهادة (صاحبها أو الأدمن)
    // DELETE /api/certificates/:id
    public function destroy(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');

        try {
            $cert = DB::table('certificates')->where('id', $id)->first();
            if (!$cert) {
                return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            }
            if ($me->role !== 'admin' && (int) $cert->user_id !== (int) $me->id) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            DB::table('certificates')->where('id', $id)->delete();
            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
