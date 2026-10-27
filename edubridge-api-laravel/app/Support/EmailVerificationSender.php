<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

final class EmailVerificationSender
{
    public function send(object $user): void
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
