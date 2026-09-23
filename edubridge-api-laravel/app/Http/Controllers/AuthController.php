<?php

namespace App\Http\Controllers;

// مسارات المصادقة: إنشاء حساب + تسجيل دخول
use Firebase\JWT\JWT;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\QueryException;

class AuthController extends Controller
{
    private function getJwtSecret(): ?string
    {
        $secret = config('services.jwt.secret') ?: env('JWT_SECRET') ?: getenv('JWT_SECRET') ?: ($_ENV['JWT_SECRET'] ?? null);
        $secret = is_string($secret) ? trim($secret) : null;

        return $secret !== '' ? $secret : null;
    }

    private function getGoogleClientId(): ?string
    {
        return env('GOOGLE_CLIENT_ID') ?: getenv('GOOGLE_CLIENT_ID') ?: ($_ENV['GOOGLE_CLIENT_ID'] ?? null);
    }

    private function getPasswordColumn(): ?string
    {
        if (Schema::hasColumn('users', 'password_hash')) {
            return 'password_hash';
        }

        if (Schema::hasColumn('users', 'password')) {
            return 'password';
        }

        return null;
    }

    private function issueToken(object $user): string
    {
        $jwtSecret = $this->getJwtSecret();
        if (!$jwtSecret) {
            throw new \RuntimeException('JWT_SECRET_MISSING');
        }

        $role = isset($user->role) && is_string($user->role) ? trim($user->role) : '';
        if ($role === '') {
            throw new \RuntimeException('USER_ROLE_MISSING');
        }

        $now = time();

        return JWT::encode(
            ['id' => $user->id, 'role' => $role, 'iat' => $now, 'exp' => $now + 7 * 24 * 3600],
            $jwtSecret,
            'HS256'
        );
    }

    // إنشاء حساب جديد
    // POST /api/auth/register
    public function register(Request $request)
    {
        $name = trim((string) $request->input('name'));
        $email = trim((string) $request->input('email'));
        $password = (string) $request->input('password');
        $role = $request->input('role');
        $phone = $request->input('phone');
        $specialty = $request->input('specialty');

        // تحقق أساسي من المدخلات
        if ($name === '' || $email === '' || $password === '' || !$role) {
            return response()->json(['error' => 'الاسم والإيميل والباسورد والدور مطلوبة'], 400);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return response()->json(['error' => 'البريد الإلكتروني غير صالح'], 422);
        }
        if (mb_strlen($password) < 8 || mb_strlen($password) > 128) {
            return response()->json(['error' => 'كلمة المرور يجب أن تكون بين 8 و128 حرفاً'], 422);
        }
        if (!in_array($role, ['parent', 'teacher', 'specialist'], true)) {
            return response()->json(['error' => 'الدور غير صالح'], 400);
        }
        if ($role === 'specialist' && $specialty !== null && !in_array($specialty, ['learning_support', 'educational', 'communication_support', 'learning_behavior'], true)) {
            return response()->json(['error' => 'التخصص غير صالح'], 422);
        }

        // الإيميل فريد — نفحص مسبقاً لنعيد 409 كما في النسخة القديمة
        if (DB::table('users')->where('email', $email)->exists()) {
            return response()->json(['error' => 'الإيميل مستخدم مسبقاً'], 409);
        }

        try {
            // ندعم قواعد البيانات القديمة والجديدة: password_hash أو password.
            $passwordColumn = $this->getPasswordColumn();
            if (!$passwordColumn) {
                return response()->json([
                    'error' => 'بنية جدول المستخدمين غير مكتملة على السيرفر',
                    'code' => 'AUTH_PASSWORD_COLUMN_MISSING',
                ], 500);
            }

            $insert = [
                'name' => $name,
                'email' => $email,
                $passwordColumn => password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]),
                'role' => $role,
            ];

            if (Schema::hasColumn('users', 'phone')) {
                $insert['phone'] = $phone;
            }
            if ($role === 'specialist' && $specialty && Schema::hasColumn('users', 'specialty')) {
                $insert['specialty'] = $specialty;
            }
            // رقم الهوية اختياري عند التسجيل (يُستكمل التوثيق لاحقاً)
            if ($request->filled('national_id') && Schema::hasColumn('users', 'national_id')) {
                $insert['national_id'] = trim((string) $request->input('national_id'));
            }
            $id = DB::table('users')->insertGetId($insert);

            $user = DB::table('users')->find($id);

            return response()->json([
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'phone' => Schema::hasColumn('users', 'phone') ? ($user->phone ?? null) : null,
                    'specialty' => Schema::hasColumn('users', 'specialty') ? ($user->specialty ?? null) : null,
                    'verification_status' => Schema::hasColumn('users', 'verification_status')
                        ? ($user->verification_status ?? 'pending')
                        : 'pending',
                ],
            ], 201);
        } catch (\Throwable $e) {
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
            $passwordColumn = $this->getPasswordColumn();
            if (!$passwordColumn) {
                return response()->json([
                    'error' => 'بنية جدول المستخدمين غير مكتملة على السيرفر',
                    'code' => 'AUTH_PASSWORD_COLUMN_MISSING',
                ], 500);
            }

            $user = DB::table('users')->where('email', $email)->first();

            // نفس الرسالة سواء الإيميل غلط أو الباسورد غلط (أأمن).
            $storedHash = $user?->{$passwordColumn} ?? null;
            if (!$user || !is_string($storedHash) || $storedHash === '' || !password_verify($password, $storedHash)) {
                return response()->json(['error' => 'بيانات الدخول غير صحيحة'], 401);
            }

            if (!isset($user->role) || !is_string($user->role) || trim($user->role) === '') {
                return response()->json([
                    'error' => 'بيانات الدور للحساب غير مكتملة على السيرفر',
                    'code' => 'AUTH_ROLE_MISSING',
                ], 500);
            }

            try {
                $token = $this->issueToken($user);
            } catch (\RuntimeException $e) {
                report($e);

                if ($e->getMessage() === 'JWT_SECRET_MISSING') {
                    return response()->json([
                        'error' => 'إعداد المصادقة على السيرفر غير مكتمل',
                        'code' => 'AUTH_JWT_SECRET_MISSING',
                    ], 500);
                }

                return response()->json([
                    'error' => 'تعذر إنشاء جلسة الدخول',
                    'code' => 'AUTH_TOKEN_FAILED',
                ], 500);
            }

            return response()->json([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'specialty' => Schema::hasColumn('users', 'specialty') ? ($user->specialty ?? null) : null,
                    'verification_status' => $user->verification_status ?? 'pending',
                ],
            ]);
        } catch (QueryException $e) {
            report($e);
            return response()->json([
                'error' => 'تعذر قراءة بيانات الحساب من قاعدة البيانات',
                'code' => 'AUTH_DB_ERROR',
            ], 500);
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'error' => 'تعذر إكمال تسجيل الدخول على السيرفر',
                'code' => 'AUTH_SERVER_ERROR',
            ], 500);
        }
    }

    // تسجيل الدخول عبر Google
    // POST /api/auth/google
    public function google(Request $request)
    {
        $idToken = $request->input('id_token') ?: $request->input('idToken');

        if (!$idToken) {
            return response()->json(['error' => 'الرمز المرسل من Google مطلوب'], 400);
        }

        $googleClientId = $this->getGoogleClientId();
        if (!$googleClientId) {
            return response()->json(['error' => 'لم يتم تكوين Google OAuth بعد'], 500);
        }

        try {
            $response = Http::get('https://oauth2.googleapis.com/tokeninfo', ['id_token' => $idToken]);

            if (!$response->successful()) {
                return response()->json(['error' => 'رمز Google غير صالح'], 401);
            }

            $payload = $response->json();
            if (($payload['aud'] ?? '') !== $googleClientId) {
                return response()->json(['error' => 'رمز Google غير صالح'], 401);
            }

            $email = $payload['email'] ?? null;
            $name = $payload['name'] ?? $payload['given_name'] ?? ($email ? explode('@', $email)[0] : 'Google User');
            $emailVerified = $payload['email_verified'] ?? false;

            if (!$email) {
                return response()->json(['error' => 'البريد الإلكتروني من Google غير متوفر'], 401);
            }
            if (!in_array($emailVerified, [true, 1, '1', 'true'], true)) {
                return response()->json(['error' => 'البريد الإلكتروني في حساب Google غير موثّق'], 401);
            }

            $user = DB::table('users')->where('email', $email)->first();

            if (!$user) {
                $passwordHash = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT, ['cost' => 10]);
                $id = DB::table('users')->insertGetId([
                    'name' => $name,
                    'email' => $email,
                    'password_hash' => $passwordHash,
                    'role' => 'parent',
                ]);

                $user = DB::table('users')
                    ->select('id', 'name', 'email', 'role', 'phone', 'created_at')
                    ->find($id);
            }

            try {
                $token = $this->issueToken($user);
            } catch (\RuntimeException $e) {
                report($e);
                return response()->json([
                    'error' => $e->getMessage() === 'JWT_SECRET_MISSING'
                        ? 'إعداد المصادقة على السيرفر غير مكتمل'
                        : 'تعذر إنشاء جلسة الدخول',
                    'code' => $e->getMessage() === 'JWT_SECRET_MISSING'
                        ? 'AUTH_JWT_SECRET_MISSING'
                        : 'AUTH_TOKEN_FAILED',
                ], 500);
            }

            return response()->json([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'verification_status' => $user->verification_status ?? 'pending',
                ],
            ]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // الملف الشخصي للمستخدم الحالي
    // GET /api/me
}
