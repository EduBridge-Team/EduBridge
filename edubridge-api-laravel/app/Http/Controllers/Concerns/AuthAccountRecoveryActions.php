<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

trait AuthAccountRecoveryActions
{
    public function forgotPassword(Request $request)
    {
        $email = trim((string) $request->input('email'));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return response()->json(['error' => 'البريد الإلكتروني غير صالح'], 422);
        }

        $user = DB::table('users')->where('email', $email)->first();

        // Keep the response identical whether the account exists or not.
        if (!$user) {
            return response()->json(['message' => 'إذا كان البريد مسجلاً فستصلك رسالة استعادة كلمة المرور.']);
        }

        if (!Schema::hasTable('password_reset_tokens')) {
            Log::error('Password reset requested but password_reset_tokens table is missing.');
            return response()->json([
                'error' => 'خدمة استعادة كلمة المرور غير جاهزة حالياً. حاول مرة أخرى بعد قليل.',
                'code' => 'PASSWORD_RESET_STORAGE_UNAVAILABLE',
            ], 503);
        }

        $token = Str::random(64);

        try {
            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $email],
                ['token' => hash('sha256', $token), 'created_at' => now()]
            );

            $frontend = rtrim((string) config('app.frontend_url', config('app.url')), '/');
            $url = $frontend . '/reset-password?email=' . urlencode($email) . '&token=' . urlencode($token);

            Mail::send('emails.auth-action', [
                'subjectLine' => 'استعادة كلمة المرور — EduBridge',
                'heading' => 'استعادة كلمة المرور',
                'userName' => $user->name,
                'intro' => 'وصلنا طلب لتغيير كلمة مرور حسابك في EduBridge. اضغط الزر التالي لإنشاء كلمة مرور جديدة.',
                'actionUrl' => $url,
                'actionText' => 'تغيير كلمة المرور',
                'expiryText' => 'صلاحية هذا الرابط 60 دقيقة فقط.',
                'ignoreText' => 'إذا لم تطلب تغيير كلمة المرور، يمكنك تجاهل هذه الرسالة بأمان.',
            ], function ($message) use ($email) {
                $message->to($email)->subject('استعادة كلمة المرور — EduBridge');
            });
        } catch (\Throwable $e) {
            // Do not leak SMTP/database internals to the client, but keep enough
            // context in production logs to diagnose delivery failures.
            Log::error('Failed to send password reset email.', [
                'email_domain' => str_contains($email, '@')
                    ? substr(strrchr($email, '@'), 1)
                    : null,
                'exception' => $e::class,
                'message' => $e->getMessage(),
            ]);

            // Remove a token that the user could never receive.
            DB::table('password_reset_tokens')->where('email', $email)->delete();

            return response()->json([
                'error' => 'تعذّر إرسال رسالة الاستعادة حالياً. حاول مرة أخرى بعد قليل.',
                'code' => 'PASSWORD_RESET_DELIVERY_FAILED',
            ], 503);
        }

        return response()->json(['message' => 'إذا كان البريد مسجلاً فستصلك رسالة استعادة كلمة المرور.']);
    }

    public function resetPassword(Request $request)
    {
        $email = trim((string) $request->input('email'));
        $token = (string) $request->input('token');
        $password = (string) $request->input('password');

        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || $token === '') {
            return response()->json(['error' => 'رابط الاستعادة غير صالح'], 422);
        }
        if (mb_strlen($password) < 8 || mb_strlen($password) > 128) {
            return response()->json(['error' => 'كلمة المرور يجب أن تكون بين 8 و128 حرفاً'], 422);
        }

        $record = DB::table('password_reset_tokens')->where('email', $email)->first();
        if (!$record || !hash_equals((string) $record->token, hash('sha256', $token))) {
            return response()->json(['error' => 'رابط الاستعادة غير صالح أو منتهي'], 422);
        }

        if (!$record->created_at || now()->diffInMinutes($record->created_at) > 60) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            return response()->json(['error' => 'انتهت صلاحية رابط الاستعادة'], 422);
        }

        $passwordColumn = $this->getPasswordColumn();
        if (!$passwordColumn) {
            return response()->json(['error' => 'بنية جدول المستخدمين غير مكتملة على السيرفر'], 500);
        }

        DB::table('users')->where('email', $email)->update([
            $passwordColumn => password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]),
        ]);
        DB::table('password_reset_tokens')->where('email', $email)->delete();

        return response()->json(['message' => 'تم تغيير كلمة المرور بنجاح. يمكنك تسجيل الدخول الآن.']);
    }

    public function resendEmailVerification(Request $request)
    {
        $email = trim((string) $request->input('email'));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return response()->json(['error' => 'البريد الإلكتروني غير صالح'], 422);
        }

        $user = DB::table('users')->where('email', $email)->first();
        if (!$user || (isset($user->email_verified_at) && $user->email_verified_at)) {
            return response()->json(['message' => 'إذا كان الحساب بحاجة للتحقق فستصلك رسالة جديدة.']);
        }

        $this->sendVerificationEmail($user);

        return response()->json(['message' => 'إذا كان الحساب بحاجة للتحقق فستصلك رسالة جديدة.']);
    }

    public function verifyEmail(Request $request)
    {
        $email = trim((string) $request->query('email'));
        $token = (string) $request->query('token');

        $record = Schema::hasTable('email_verification_tokens')
            ? DB::table('email_verification_tokens')->where('email', $email)->first()
            : null;

        $valid = $record
            && $token !== ''
            && hash_equals((string) $record->token, hash('sha256', $token))
            && $record->created_at
            && now()->diffInHours($record->created_at) <= 24;

        $frontend = rtrim((string) config('app.frontend_url', config('app.url')), '/');

        if (!$valid) {
            return redirect($frontend . '/login?verified=0');
        }

        DB::table('users')->where('email', $email)->update(['email_verified_at' => now()]);
        DB::table('email_verification_tokens')->where('email', $email)->delete();

        return redirect($frontend . '/login?verified=1');
    }

    private function sendVerificationEmail(object $user): void
    {
        if (!Schema::hasTable('email_verification_tokens')) {
            return;
        }

        $token = Str::random(64);
        DB::table('email_verification_tokens')->updateOrInsert(
            ['email' => $user->email],
            ['token' => hash('sha256', $token), 'created_at' => now()]
        );

        $backend = rtrim((string) config('app.url'), '/');
        $url = $backend . '/api/auth/verify-email?email=' . urlencode($user->email) . '&token=' . urlencode($token);

        Mail::send('emails.auth-action', [
            'subjectLine' => 'تأكيد البريد الإلكتروني — EduBridge',
            'heading' => 'تأكيد بريدك الإلكتروني',
            'userName' => $user->name,
            'intro' => 'بقيت خطوة واحدة لإكمال إنشاء حسابك في EduBridge. أكد بريدك الإلكتروني عبر الزر التالي.',
            'actionUrl' => $url,
            'actionText' => 'تأكيد البريد الإلكتروني',
            'expiryText' => 'صلاحية رابط التأكيد 24 ساعة.',
            'ignoreText' => 'إذا لم تقم بإنشاء هذا الحساب، يمكنك تجاهل هذه الرسالة.',
        ], function ($message) use ($user) {
            $message->to($user->email)->subject('تأكيد البريد الإلكتروني — EduBridge');
        });
    }
}
