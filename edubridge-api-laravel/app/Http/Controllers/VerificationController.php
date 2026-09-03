<?php

namespace App\Http\Controllers;

// توثيق الهوية (البطاقات 1، 4، 9)
// - المستخدم يرفع هويته ورقمها (تصبح الحالة "بانتظار التوثيق").
// - الأدمن يستعرض الطلبات المعلّقة ويعتمد/يرفض المستخدمين وهوية الأطفال.
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;

class VerificationController extends Controller
{
    private const STATUSES = ['pending', 'verified', 'rejected'];

    // رفع/تحديث المستخدم لبيانات هويته
    // POST /api/me/identity   body: { national_id?, id_document_url? }
    public function submitMine(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        $updates = [];
        if ($request->has('national_id')) {
            $nid = trim((string) $request->input('national_id'));
            $updates['national_id'] = $nid !== '' ? $nid : null;
        }
        if ($request->has('id_document_url')) {
            $url = trim((string) $request->input('id_document_url'));
            $updates['id_document_url'] = $url !== '' ? $url : null;
        }

        if (empty($updates)) {
            return response()->json(['error' => 'لا توجد بيانات لتحديثها'], 400);
        }

        // إعادة الحالة إلى "بانتظار التوثيق" عند إرسال مستندات جديدة
        $updates['verification_status'] = 'pending';
        $updates['verification_note'] = null;
        $updates['verified_at'] = null;

        try {
            DB::table('users')->where('id', $user->id)->update($updates);

            $fresh = DB::table('users')
                ->select('id', 'name', 'email', 'role', 'national_id',
                    'id_document_url', 'verification_status')
                ->find($user->id);

            return response()->json(['user' => $fresh]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // حالة توثيق المستخدم الحالي (يستعملها التطبيق/الموقع لمنع الميزات الحساسة)
    // GET /api/me/verification
    public function myStatus(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $row = DB::table('users')
            ->select('verification_status', 'verification_note', 'national_id',
                'id_document_url', 'verified_at')
            ->find($user->id);

        return response()->json(['verification' => $row]);
    }

    // استعراض المستخدمين حسب حالة التوثيق (أدمن)
    // GET /api/verifications/users?status=pending
    public function users(Request $request)
    {
        try {
            $query = DB::table('users')
                ->select('id', 'name', 'email', 'role', 'phone', 'national_id',
                    'id_document_url', 'verification_status', 'verification_note',
                    'verified_at', 'created_at')
                ->orderByDesc('created_at');

            $status = $request->query('status');
            if ($status && in_array($status, self::STATUSES, true)) {
                $query->where('verification_status', $status);
            }
            if ($request->query('role')) {
                $query->where('role', $request->query('role'));
            }

            return response()->json(['users' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // اعتماد/رفض توثيق مستخدم (أدمن)
    // PUT /api/verifications/users/:id   body: { status, note? }
    public function reviewUser(Request $request, $id)
    {
        $status = $request->input('status');
        if (!in_array($status, ['verified', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون verified أو rejected'], 400);
        }

        try {
            $user = DB::table('users')->where('id', $id)->first();
            if (!$user) {
                return response()->json(['error' => 'المستخدم غير موجود'], 404);
            }

            DB::table('users')->where('id', $id)->update([
                'verification_status' => $status,
                'verification_note' => $request->input('note'),
                'verified_at' => $status === 'verified' ? now() : null,
            ]);

            Notify::toUser(
                $id,
                $status === 'verified' ? 'تم توثيق حسابك' : 'لم يتم توثيق حسابك',
                $status === 'verified'
                    ? 'تم توثيق هويتك بنجاح، يمكنك الآن استخدام كامل الميزات.'
                    : 'تم رفض التوثيق: ' . ($request->input('note') ?: 'يرجى إعادة رفع مستندات صحيحة'),
                'verification'
            );

            $fresh = DB::table('users')
                ->select('id', 'name', 'email', 'role', 'verification_status',
                    'verification_note', 'verified_at')
                ->find($id);

            return response()->json(['user' => $fresh]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // استعراض الأطفال حسب حالة توثيق المستندات (أدمن)
    // GET /api/verifications/children?status=pending
    public function children(Request $request)
    {
        try {
            $query = DB::table('children')
                ->select('id', 'name', 'child_national_id', 'guardian_national_id',
                    'guardian_id_document_url', 'kinship_document_url',
                    'doc_verification_status', 'doc_verification_note', 'created_at')
                ->orderByDesc('created_at');

            $status = $request->query('status');
            if ($status && in_array($status, self::STATUSES, true)) {
                $query->where('doc_verification_status', $status);
            }

            return response()->json(['children' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // اعتماد/رفض توثيق مستندات طفل (أدمن)
    // PUT /api/verifications/children/:id   body: { status, note? }
    public function reviewChild(Request $request, $id)
    {
        $status = $request->input('status');
        if (!in_array($status, ['verified', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون verified أو rejected'], 400);
        }

        try {
            $child = DB::table('children')->where('id', $id)->first();
            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            DB::table('children')->where('id', $id)->update([
                'doc_verification_status' => $status,
                'doc_verification_note' => $request->input('note'),
            ]);

            Notify::toChildParents(
                $id,
                $status === 'verified' ? 'تم توثيق بيانات الطفل' : 'لم يتم توثيق بيانات الطفل',
                $status === 'verified'
                    ? 'تم التحقق من هوية وصلة قرابة الطفل ' . ($child->name ?? '') . ' بنجاح.'
                    : 'تم رفض توثيق بيانات الطفل ' . ($child->name ?? '') . ': ' . ($request->input('note') ?: 'يرجى إعادة رفع المستندات'),
                'verification'
            );

            return response()->json(['child' => DB::table('children')->find($id)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
