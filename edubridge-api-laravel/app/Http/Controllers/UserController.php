<?php

namespace App\Http\Controllers;

// إدارة المستخدمين — للأدمن فقط (لوحة التحكم الإدارية)
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserController extends Controller
{
    // الأدوار المسموح بها — نفس قيد قاعدة البيانات
    private const ROLES = ['parent', 'teacher', 'specialist', 'admin'];

    // عرض كل المستخدمين (أدمن)، مع فلترة اختيارية حسب الدور: ?role=parent
    // GET /api/users
    public function index(Request $request)
    {
        try {
            $query = DB::table('users')
                // لا نُرجع password_hash أبداً
                ->select('id', 'name', 'email', 'role', 'phone', 'created_at')
                ->orderBy('name');

            $role = $request->query('role');
            if ($role) {
                $query->where('role', $role);
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
                ->select('id', 'name', 'email', 'role', 'phone', 'created_at')
                ->find($id);

            return response()->json(['user' => $fresh]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
