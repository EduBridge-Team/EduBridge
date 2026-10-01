<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

trait UserCreateActions
{
    public function store(Request $request)
    {
        $actor = $request->attributes->get('jwt_user');
        if (($actor->role ?? null) !== 'admin') {
            return response()->json(['error' => 'إنشاء هذه الحسابات متاح للأدمن فقط'], 403);
        }
        $data = $request->only(['name', 'email', 'password', 'password_confirmation', 'role', 'phone']);
        $validator = Validator::make($data, [
            'name' => 'required|string|max:150',
            'email' => 'required|email|max:255',
            'password' => 'required|string|min:8|max:128|confirmed',
            'role' => 'required|in:institution,ministry',
            'phone' => 'nullable|string|max:20',
        ], [
            'role.in' => 'اختر حساب مؤسسة أو وزارة',
            'password.min' => 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
            'password.confirmed' => 'تأكيد كلمة المرور غير مطابق',
            'email.email' => 'البريد الإلكتروني غير صالح',
            'name.required' => 'اسم المؤسسة أو الوزارة مطلوب',
        ]);
        if ($validator->fails()) return response()->json(['error' => $validator->errors()->first()], 422);
        $email = mb_strtolower(trim($data['email']));
        $name = trim($data['name']);
        if ($name === '') return response()->json(['error' => 'الاسم مطلوب'], 422);
        if (DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->exists()) {
            return response()->json(['error' => 'البريد الإلكتروني مستخدم بالفعل'], 409);
        }
        try {
            $insert = ['name' => $name, 'email' => $email, 'role' => $data['role']];
            $hash = password_hash($data['password'], PASSWORD_BCRYPT, ['cost' => 10]);
            $hasPassword = false;
            foreach (['password_hash', 'password'] as $column) {
                if (Schema::hasColumn('users', $column)) { $insert[$column] = $hash; $hasPassword = true; }
            }
            if (!$hasPassword) return response()->json(['error' => 'بنية حسابات المستخدمين غير مكتملة'], 500);
            if (Schema::hasColumn('users', 'phone')) $insert['phone'] = trim($data['phone'] ?? '') ?: null;
            if (Schema::hasColumn('users', 'verification_status')) $insert['verification_status'] = 'pending';
            foreach (['created_at', 'updated_at'] as $column) {
                if (Schema::hasColumn('users', $column)) $insert[$column] = now();
            }
            $id = DB::table('users')->insertGetId($insert);
            // Explicit public fields: credentials and hashes never leave the API.
            return response()->json(['user' => [
                'id' => $id, 'name' => $name, 'email' => $email, 'role' => $data['role'],
                'phone' => $insert['phone'] ?? null, 'verification_status' => 'pending',
            ]], 201);
        } catch (QueryException $e) {
            if (in_array((string) $e->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'البريد الإلكتروني مستخدم بالفعل'], 409);
            }
            report($e);
            return response()->json(['error' => 'تعذّر إنشاء الحساب'], 500);
        }
    }
}
