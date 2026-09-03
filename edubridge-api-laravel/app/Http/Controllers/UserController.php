<?php

namespace App\Http\Controllers;

// إدارة المستخدمين — الأدمن يدير الكل؛ المعلّم/المختص يستعرض قائمة المعلّمين فقط
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserController extends Controller
{
    // الأدوار المسموح بها — نفس قيد قاعدة البيانات
    private const ROLES = ['parent', 'teacher', 'specialist', 'admin', 'ministry', 'institution'];

    // عرض المستخدمين
    // - الأدمن: كل المستخدمين، مع فلترة اختيارية حسب الدور: ?role=parent
    // - المعلّم/المختص: قائمة المعلّمين فقط (لتعيين معلّم للطفل) — إصلاح ظهور المعلّمين
    // GET /api/users
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = DB::table('users')
                // لا نُرجع password_hash أبداً
                ->select('id', 'name', 'email', 'role', 'phone', 'national_id',
                    'verification_status', 'verified_at', 'created_at')
                ->orderBy('name');

            if ($user->role === 'admin') {
                $role = $request->query('role');
                if ($role) {
                    $query->where('role', $role);
                }
            } else {
                // غير الأدمن (معلّم/مختص) لا يرى إلا المعلّمين، وبحقول محدودة
                $query = DB::table('users')
                    ->select('id', 'name', 'email', 'phone', 'verification_status')
                    ->where('role', 'teacher')
                    ->orderBy('name');
            }

            return response()->json(['users' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تعديل مستخدم (أدمن): الاسم / البريد / الدور / الهاتف
    // PUT /api/users/:id
    public function update(Request $request, $id)
    {
        try {
            $user = DB::table('users')->where('id', $id)->first();
            if (!$user) {
                return response()->json(['error' => 'المستخدم غير موجود'], 404);
            }

            $updates = [];

            // الاسم
            if ($request->has('name')) {
                $name = trim((string) $request->input('name'));
                if ($name === '') {
                    return response()->json(['error' => 'الاسم مطلوب'], 400);
                }
                $updates['name'] = $name;
            }

            // البريد — مع التحقق من التفرّد (مع تجاهل نفس المستخدم)
            if ($request->has('email')) {
                $email = trim((string) $request->input('email'));
                if ($email === '') {
                    return response()->json(['error' => 'البريد الإلكتروني مطلوب'], 400);
                }
                $taken = DB::table('users')
                    ->where('email', $email)
                    ->where('id', '!=', $id)
                    ->exists();
                if ($taken) {
                    return response()->json(['error' => 'البريد الإلكتروني مستخدم بالفعل'], 409);
                }
                $updates['email'] = $email;
            }

            // الدور — يجب أن يكون ضمن القيم المسموحة
            if ($request->has('role')) {
                $role = $request->input('role');
                if (!in_array($role, self::ROLES, true)) {
                    return response()->json(['error' => 'الدور غير صالح'], 400);
                }
                $updates['role'] = $role;
            }

            // الهاتف (اختياري — يقبل الفراغ)
            if ($request->has('phone')) {
                $phone = trim((string) $request->input('phone'));
                $updates['phone'] = $phone !== '' ? $phone : null;
            }

            if (!empty($updates)) {
                DB::table('users')->where('id', $id)->update($updates);
            }

            $fresh = DB::table('users')
                ->select('id', 'name', 'email', 'role', 'phone', 'national_id',
                    'verification_status', 'verified_at', 'created_at')
                ->find($id);

            return response()->json(['user' => $fresh]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // حذف مستخدم (أدمن) — البطاقة 11
    // DELETE /api/users/:id
    public function destroy(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');

        // منع الأدمن من حذف حسابه بنفسه (حماية من فقدان الوصول)
        if ((int) $me->id === (int) $id) {
            return response()->json(['error' => 'لا يمكنك حذف حسابك الخاص'], 400);
        }

        try {
            $user = DB::table('users')->where('id', $id)->first();
            if (!$user) {
                return response()->json(['error' => 'المستخدم غير موجود'], 404);
            }

            DB::table('users')->where('id', $id)->delete();

            return response()->json(['message' => 'تم حذف المستخدم']);
        } catch (\Exception $e) {
            report($e);
            // قد يفشل الحذف بسبب قيود مرجعية (مثل معلّم مسند لأطفال)
            return response()->json(['error' => 'تعذّر حذف المستخدم — قد يكون مرتبطاً ببيانات أخرى'], 409);
        }
    }
}
