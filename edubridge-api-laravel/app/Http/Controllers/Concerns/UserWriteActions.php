<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait UserWriteActions
{
    public function update(Request $request, $id)
    {
        try {
            $user = DB::table('users')->where('id', $id)->first();
            if (!$user) {
                return response()->json(['error' => 'المستخدم غير موجود'], 404);
            }

            $updates = [];

            if ($request->has('name')) {
                $name = trim((string) $request->input('name'));
                if ($name === '') {
                    return response()->json(['error' => 'الاسم مطلوب'], 400);
                }
                $updates['name'] = $name;
            }

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

            if ($request->has('role')) {
                $role = $request->input('role');
                if (!in_array($role, self::ROLES, true)) {
                    return response()->json(['error' => 'الدور غير صالح'], 400);
                }
                $updates['role'] = $role;
            }

            if ($request->has('phone')) {
                $phone = trim((string) $request->input('phone'));
                $updates['phone'] = $phone !== '' ? $phone : null;
            }

            if (!empty($updates)) {
                DB::table('users')->where('id', $id)->update($updates);
            }

            $fresh = DB::table('users')
                ->select(
                    'id',
                    'name',
                    'email',
                    'role',
                    'phone',
                    'national_id',
                    'verification_status',
                    'verified_at',
                    'created_at'
                )
                ->find($id);

            if ($fresh && Schema::hasColumn('users', 'specialty')) {
                $fresh->specialty = DB::table('users')->where('id', $id)->value('specialty');
            }

            return response()->json(['user' => $fresh]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');

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

            return response()->json([
                'error' => 'تعذّر حذف المستخدم — قد يكون مرتبطاً ببيانات أخرى',
            ], 409);
        }
    }
}
