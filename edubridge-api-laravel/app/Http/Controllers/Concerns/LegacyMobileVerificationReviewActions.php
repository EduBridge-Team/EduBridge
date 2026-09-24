<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait LegacyMobileVerificationReviewActions
{
    public function approveVerification(Request $request, $id)
    {
        return $this->reviewVerification((int) $id, true);
    }

    public function rejectVerification(Request $request, $id)
    {
        return $this->reviewVerification((int) $id, false);
    }

    private function reviewVerification(int $encodedId, bool $approve)
    {
        [$sourceId, $type] = $this->decodeId($encodedId);

        if ($sourceId <= 0 || !in_array($type, [1,2,3], true)) {
            return response()->json(['error' => 'طلب التوثيق غير صالح'], 404);
        }

        $status = $approve ? 'verified' : 'rejected';

        if ($type === 1) {
            $row = DB::table('users')->where('id', $sourceId)->first();
            if (!$row) {
                return response()->json(['error' => 'المستخدم غير موجود'], 404);
            }

            DB::table('users')->where('id', $sourceId)->update([
                'verification_status' => $status,
                'verified_at' => $approve ? now() : null,
            ]);

            Notify::toUser(
                $sourceId,
                $approve ? 'تم توثيق حسابك' : 'تم رفض توثيق حسابك',
                $approve ? 'تم توثيق هويتك بنجاح.' : 'يرجى إعادة رفع مستندات صحيحة.',
                'verification'
            );
        } elseif ($type === 2) {
            $row = DB::table('children')->where('id', $sourceId)->first();
            if (!$row) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            DB::table('children')->where('id', $sourceId)->update([
                'doc_verification_status' => $status,
            ]);

            Notify::toChildParents(
                $sourceId,
                $approve ? 'تم توثيق بيانات الطفل' : 'تم رفض توثيق بيانات الطفل',
                $approve ? 'تم التحقق من المستندات بنجاح.' : 'يرجى إعادة رفع المستندات.',
                'verification'
            );
        } else {
            $row = DB::table('certificates')->where('id', $sourceId)->first();
            if (!$row) {
                return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            }

            DB::table('certificates')->where('id', $sourceId)->update([
                'status' => $status,
            ]);

            Notify::toUser(
                $row->user_id,
                $approve ? 'تم اعتماد شهادتك' : 'تم رفض شهادتك',
                ($approve ? 'تم اعتماد الشهادة: ' : 'تم رفض الشهادة: ') . $row->title,
                'certificate'
            );
        }

        return response()->json(['ok' => true]);
    }
}
