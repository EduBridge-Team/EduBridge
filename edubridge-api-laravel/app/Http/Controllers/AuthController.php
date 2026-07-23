<?php

namespace App\Http\Controllers;

// مسارات المصادقة: إنشاء حساب + تسجيل دخول
use Firebase\JWT\JWT;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    // إنشاء حساب جديد
    // POST /api/auth/register
    public function register(Request $request)
    {
        $name = $request->input('name');
        $email = $request->input('email');
        $password = $request->input('password');
        $role = $request->input('role');
        $phone = $request->input('phone');

        // تحقق أساسي من المدخلات
        if (!$name || !$email || !$password || !$role) {
            return response()->json(['error' => 'الاسم والإيميل والباسورد والدور مطلوبة'], 400);
        }
        if (!in_array($role, ['parent', 'teacher', 'specialist', 'admin'])) {
            return response()->json(['error' => 'الدور غير صالح'], 400);
        }

        // الإيميل فريد — نفحص مسبقاً لنعيد 409 كما في النسخة القديمة
        if (DB::table('users')->where('email', $email)->exists()) {
            return response()->json(['error' => 'الإيميل مستخدم مسبقاً'], 409);
        }

        try {
            // تشفير الباسورد قبل التخزين (bcrypt)
            $id = DB::table('users')->insertGetId([
                'name' => $name,
                'email' => $email,
                'password_hash' => password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]),
                'role' => $role,
                'phone' => $phone,
            ]);

            $user = DB::table('users')
                ->select('id', 'name', 'email', 'role', 'phone', 'created_at')
                ->find($id);

            return response()->json(['user' => $user], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تسجيل الدخول
    // POST /api/auth/login
    public function login(Request $request)
    {
        $email = $request->input('email');
        $password = $request->input('password');

        if (!$email || !$password) {
            return response()->json(['error' => 'الإيميل والباسورد مطلوبان'], 400);
        }

        try {
            $user = DB::table('users')->where('email', $email)->first();

            // نفس الرسالة سواء الإيميل غلط أو الباسورد غلط (أأمن)
            if (!$user || !password_verify($password, $user->password_hash)) {
                return response()->json(['error' => 'بيانات الدخول غير صحيحة'], 401);
            }

            // إنشاء التوكن — نفس الحمولة والصلاحية (7 أيام)
            $now = time();
            $token = JWT::encode(
                ['id' => $user->id, 'role' => $user->role, 'iat' => $now, 'exp' => $now + 7 * 24 * 3600],
                env('JWT_SECRET'),
                'HS256'
            );

            return response()->json([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // مسار محمي — يعيد حمولة التوكن
    // GET /api/me
    public function me(Request $request)
    {
        return response()->json(['user' => $request->attributes->get('jwt_user')]);
    }
}
