<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

trait AuthRegisterHelpers
{
    private function registerInput(Request $request): array
    {
        return [
            'name' => trim((string) $request->input('name')),
            'email' => trim((string) $request->input('email')),
            'password' => (string) $request->input('password'),
            'role' => $request->input('role'),
            'phone' => $request->input('phone'),
            'specialty' => $request->input('specialty'),
        ];
    }

    private function registerValidationError(array $input)
    {
        if (
            $input['name'] === ''
            || $input['email'] === ''
            || $input['password'] === ''
            || !$input['role']
        ) {
            return response()->json(['error' => 'الاسم والإيميل والباسورد والدور مطلوبة'], 400);
        }

        if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
            return response()->json(['error' => 'البريد الإلكتروني غير صالح'], 422);
        }

        if (mb_strlen($input['password']) < 8 || mb_strlen($input['password']) > 128) {
            return response()->json(['error' => 'كلمة المرور يجب أن تكون بين 8 و128 حرفاً'], 422);
        }

        if (!in_array($input['role'], ['parent', 'teacher', 'specialist'], true)) {
            return response()->json(['error' => 'الدور غير صالح'], 400);
        }

        if (
            $input['role'] === 'specialist'
            && $input['specialty'] !== null
            && !in_array(
                $input['specialty'],
                ['learning_support', 'educational', 'communication_support', 'learning_behavior'],
                true
            )
        ) {
            return response()->json(['error' => 'التخصص غير صالح'], 422);
        }

        return null;
    }

    private function registerInsertPayload(
        Request $request,
        array $input,
        string $passwordColumn
    ): array {
        $insert = [
            'name' => $input['name'],
            'email' => $input['email'],
            $passwordColumn => password_hash($input['password'], PASSWORD_BCRYPT, ['cost' => 10]),
            'role' => $input['role'],
        ];

        if (Schema::hasColumn('users', 'phone')) {
            $insert['phone'] = $input['phone'];
        }
        if (
            $input['role'] === 'specialist'
            && $input['specialty']
            && Schema::hasColumn('users', 'specialty')
        ) {
            $insert['specialty'] = $input['specialty'];
        }
        if ($request->filled('national_id') && Schema::hasColumn('users', 'national_id')) {
            $insert['national_id'] = trim((string) $request->input('national_id'));
        }

        return $insert;
    }

    private function serializeRegisteredUser($user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'phone' => Schema::hasColumn('users', 'phone') ? ($user->phone ?? null) : null,
            'specialty' => Schema::hasColumn('users', 'specialty') ? ($user->specialty ?? null) : null,
            'verification_status' => Schema::hasColumn('users', 'verification_status')
                ? ($user->verification_status ?? 'pending')
                : 'pending',
        ];
    }
}
