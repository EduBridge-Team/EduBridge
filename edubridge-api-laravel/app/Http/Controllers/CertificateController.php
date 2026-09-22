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
        $url = trim((string) $request->input('url', ''));
        $file = $request->file('file');

        if ($title === '') {
            return response()->json(['error' => 'عنوان الشهادة مطلوب'], 400);
        }

        if ($file) {
            if (!$file->isValid()) {
                return response()->json(['error' => 'تعذّر قراءة ملف الشهادة'], 422);
            }
            $ext = strtolower((string) $file->getClientOriginalExtension());
            if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'pdf'], true)) {
                return response()->json(['error' => 'صيغة الشهادة غير مدعومة'], 422);
            }
            if ((int) $file->getSize() > 10 * 1024 * 1024) {
                return response()->json(['error' => 'حجم الشهادة يتجاوز 10MB'], 422);
            }

            $mime = strtolower((string) $file->getMimeType());
            if (!in_array($mime, ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'], true)) {
                return response()->json(['error' => 'نوع ملف الشهادة غير مدعوم'], 422);
            }

            $dir = storage_path('app/private/user-files/' . (int) $me->id);
            if (!is_dir($dir)) {
                @mkdir($dir, 0750, true);
            }
            $name = 'certificate_' . $me->id . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
            $file->move($dir, $name);
            $url = '/api/private-files/user/' . (int) $me->id . '/' . $name;
        }

        if ($url === '') {
            return response()->json(['error' => 'ملف الشهادة مطلوب'], 400);
        }

        $expectedPrefix = '/api/private-files/user/' . (int) $me->id . '/';
        if (!str_starts_with($url, $expectedPrefix)) {
            return response()->json(['error' => 'يجب رفع ملف الشهادة من خلال التخزين الآمن'], 422);
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

            $prefix = '/api/private-files/user/' . (int) $cert->user_id . '/';
            if (is_string($cert->url) && str_starts_with($cert->url, $prefix)) {
                $filename = basename(parse_url($cert->url, PHP_URL_PATH) ?: $cert->url);
                if (preg_match('/^[A-Za-z0-9._-]+$/', $filename)) {
                    $path = storage_path('app/private/user-files/' . (int) $cert->user_id . '/' . $filename);
                    if (is_file($path)) {
                        @unlink($path);
                    }
                }
            }

            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
