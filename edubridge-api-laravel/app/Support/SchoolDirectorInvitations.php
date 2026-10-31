<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

final class SchoolDirectorInvitations
{
    // Caller holds the school row lock. Tokens are only sent to the named mailbox.
    public static function issue(object $school, string $email, int $actor): array
    {
        DB::table('school_director_invitations')->where('school_id', $school->id)
            ->whereNull('accepted_at')->whereNull('revoked_at')->update(['revoked_at' => now(), 'updated_at' => now()]);
        $assignment = DB::table('school_management_assignments')->where('school_id', $school->id)
            ->where('role', 'director')->whereNull('ends_at')->value('id');
        $token = Str::random(64);
        $expires = now()->addDays(7);
        $id = DB::table('school_director_invitations')->insertGetId([
            'school_id' => $school->id, 'email' => $email, 'token_hash' => hash('sha256', $token),
            'invited_by' => $actor, 'expected_director_assignment_id' => $assignment,
            'expires_at' => $expires, 'created_at' => now(), 'updated_at' => now(),
        ]);
        DB::afterCommit(function () use ($school, $email, $token) {
            try {
                $url = rtrim((string) config('app.frontend_url', config('app.url')), '/')
                    . '/school/invitation#token=' . rawurlencode($token);
                Mail::send('emails.auth-action', [
                    'subjectLine' => 'EduBridge school director invitation',
                    'heading' => 'دعوة لإدارة مدرسة / School director invitation', 'userName' => $email,
                    'intro' => 'دعوة لإدارة '.$school->name.'. Register or sign in using this email, verify it, then accept the invitation.',
                    'actionUrl' => $url, 'actionText' => 'مراجعة الدعوة / Review invitation',
                    'expiryText' => 'تنتهي الدعوة خلال 7 أيام / Expires in 7 days.',
                    'ignoreText' => 'يمكن تجاهل هذه الرسالة إن لم تكن تخصك / Ignore this message if it is not for you.',
                ], fn ($message) => $message->to($email)->subject('EduBridge school director invitation'));
            } catch (\Throwable $error) {
                report($error); // A failed delivery can be retried by issuing a new invitation.
            }
        });
        return ['id' => $id, 'email' => $email, 'expires_at' => $expires->toIso8601String()];
    }
}
