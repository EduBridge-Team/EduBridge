<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Support\Facades\DB;

trait SpecialistSuggestionResponseHelpers
{
    private function processSuggestionResponse($user, int $id, bool $accept, string $rejectionReason): array
    {
        return DB::transaction(function () use ($user, $id, $accept, $rejectionReason) {
            $suggestion = DB::table('specialist_suggestions')
                ->where('id', $id)
                ->lockForUpdate()
                ->first();

            if (!$suggestion) {
                return ['status' => 404, 'body' => ['error' => 'الاقتراح غير موجود']];
            }
            if ($user->role === 'specialist' && (int) $suggestion->specialist_id !== (int) $user->id) {
                return ['status' => 403, 'body' => ['error' => 'هذا الاقتراح ليس موجهاً لك']];
            }
            if ($suggestion->status !== 'pending') {
                return ['status' => 409, 'body' => ['error' => 'تمت معالجة هذا الاقتراح مسبقاً']];
            }

            DB::table('specialist_suggestions')->where('id', $id)->update([
                'status' => $accept ? 'accepted' : 'rejected',
                'rejection_reason' => $accept ? null : ($rejectionReason !== '' ? $rejectionReason : null),
                'responded_at' => now(),
                'updated_at' => now(),
            ]);

            if ($accept) {
                DB::table('child_specialist')->insertOrIgnore([
                    'child_id' => $suggestion->child_id,
                    'specialist_id' => $suggestion->specialist_id,
                    'specialty' => $suggestion->specialty,
                    'assigned_at' => now(),
                    'created_at' => now(),
                ]);
            }

            return ['status' => 200, 'body' => ['suggestion' => $this->findSuggestion($id)]];
        });
    }

    private function notifySuggestionResponse($suggestion, bool $accept): void
    {
        $childName = $suggestion->child_name ?? '';
        $specialistName = $suggestion->specialist_name ?? '';

        Notify::toUser(
            $suggestion->suggested_by,
            $accept ? 'تم قبول اقتراح المتابعة' : 'تم رفض اقتراح المتابعة',
            $specialistName . ($accept ? ' وافق على متابعة ' : ' رفض متابعة ') . $childName . '.',
            $accept ? 'suggestion_accepted' : 'suggestion_rejected'
        );

        Notify::toChildParents(
            $suggestion->child_id,
            $accept ? 'تم تأكيد المختص' : 'تحديث اقتراح المختص',
            $accept
                ? 'وافق المختص ' . $specialistName . ' على متابعة ' . $childName . '.'
                : 'تم رفض اقتراح متابعة ' . $childName . ' من المختص ' . $specialistName . '.',
            $accept ? 'suggestion_accepted' : 'suggestion_rejected'
        );
    }
}
