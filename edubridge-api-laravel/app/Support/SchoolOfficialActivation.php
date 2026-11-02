<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

final class SchoolOfficialActivation
{
    // The caller holds a school lock inside a transaction. Never return a token
    // to the administrator; only the official school's mailbox receives it.
    public static function issue(object $school): void
    {
        $token = Str::random(64);
        DB::table('school_account_activation_tokens')->updateOrInsert(
            ['school_id' => $school->id],
            [
                'token_hash' => hash('sha256', $token),
                'expires_at' => now()->addDay(),
                'consumed_at' => null,
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );

        DB::afterCommit(function () use ($school, $token) {
            try {
                $frontend = rtrim((string) config('app.frontend_url', config('app.url')), '/');
                // Fragment is not sent to the web server or stored in access logs.
                $url = $frontend . '/school/activate#token=' . rawurlencode($token);
                Mail::send('emails.auth-action', [
                    'subjectLine' => 'تفعيل البريد الرسمي للمدرسة — EduBridge',
                    'heading' => 'تفعيل حساب المدرسة الرسمي',
                    'userName' => $school->name,
                    'intro' => 'تم تسجيل مدرستكم في EduBridge. أكّدوا ملكية البريد الرسمي وأنشئوا كلمة مرور مستقلة لحساب المدرسة. هذا الحساب لا يمنح صلاحيات مدير المدرسة.',
                    'actionUrl' => $url,
                    'actionText' => 'تفعيل حساب المدرسة',
                    'expiryText' => 'تنتهي صلاحية الرابط خلال 24 ساعة.',
                    'ignoreText' => 'إذا لم تطلبوا إنشاء المدرسة، تجاهلوا هذه الرسالة وتواصلوا مع المسؤول.',
                ], fn ($message) => $message->to($school->email)->subject('تفعيل حساب المدرسة الرسمي — EduBridge'));
            } catch (\Throwable $e) {
                report($e);
                // The admin can resend from the authorized endpoint.
            }
        });
    }
}
