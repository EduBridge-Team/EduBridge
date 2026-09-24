<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait AuthRegisterActions
{
    public function register(Request $request)
    {
        $input = $this->registerInput($request);
        $validationError = $this->registerValidationError($input);
        if ($validationError) {
            return $validationError;
        }

        if (DB::table('users')->where('email', $input['email'])->exists()) {
            return response()->json(['error' => 'الإيميل مستخدم مسبقاً'], 409);
        }

        try {
            $passwordColumn = $this->getPasswordColumn();
            if (!$passwordColumn) {
                return response()->json([
                    'error' => 'بنية جدول المستخدمين غير مكتملة على السيرفر',
                    'code' => 'AUTH_PASSWORD_COLUMN_MISSING',
                ], 500);
            }

            $insert = $this->registerInsertPayload($request, $input, $passwordColumn);
            $id = DB::table('users')->insertGetId($insert);
            $user = DB::table('users')->find($id);

            try {
                $this->sendVerificationEmail($user);
            } catch (\Throwable $mailError) {
                report($mailError);
            }

            return response()->json([
                'user' => $this->serializeRegisteredUser($user),
            ], 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
