<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

final class VerificationRequirements
{
    public static function certificateStatus(int $userId): string
    {
        if (DB::table('certificates')->where('user_id', $userId)->where('status', 'verified')->exists()) {
            return 'verified';
        }

        if (DB::table('certificates')->where('user_id', $userId)->where('status', 'pending')->exists()) {
            return 'pending';
        }

        if (DB::table('certificates')->where('user_id', $userId)->where('status', 'rejected')->exists()) {
            return 'rejected';
        }

        return 'none';
    }

    public static function snapshot(object $user): array
    {
        $role = (string) ($user->role ?? '');
        $verificationStatus = (string) ($user->verification_status ?? 'pending');

        if (!in_array($role, ['teacher', 'specialist'], true)) {
            return [
                'verification_status' => $verificationStatus,
                'identity_status' => $verificationStatus,
                'certificate_status' => 'not_required',
                'requirements_complete' => $verificationStatus === 'verified',
            ];
        }

        $identityStatus = (string) ($user->identity_status ?? 'pending');
        $certificateStatus = self::certificateStatus((int) $user->id);
        $complete = $identityStatus === 'verified' && $certificateStatus === 'verified';

        if ($identityStatus === 'rejected') {
            $overall = 'rejected';
        } elseif ($complete) {
            $overall = 'verified';
        } elseif ($identityStatus === 'verified' && $certificateStatus === 'rejected') {
            $overall = 'rejected';
        } else {
            $overall = 'pending';
        }

        return [
            'verification_status' => $overall,
            'identity_status' => $identityStatus,
            'certificate_status' => $certificateStatus,
            'requirements_complete' => $complete,
        ];
    }

    public static function syncUserStatus(int $userId): array
    {
        $user = DB::table('users')->where('id', $userId)->first();
        if (!$user) {
            return [
                'verification_status' => 'pending',
                'identity_status' => 'pending',
                'certificate_status' => 'none',
                'requirements_complete' => false,
            ];
        }

        $snapshot = self::snapshot($user);

        DB::table('users')->where('id', $userId)->update([
            'verification_status' => $snapshot['verification_status'],
            'verified_at' => $snapshot['requirements_complete'] ? ($user->verified_at ?? now()) : null,
        ]);

        return $snapshot;
    }
}
