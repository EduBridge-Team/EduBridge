<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use App\Support\VerificationRequirements;
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
                'identity_status' => $status,
            ]);

            $snapshot = VerificationRequirements::syncUserStatus($sourceId);

            Notify::toUser(
                $sourceId,
                $approve
                    ? ($snapshot['requirements_complete'] ? 'تم توثيق حسابك' : 'تم اعتماد هويتك')
                    : 'تم رفض هويتك',
                $approve
                    ? ($snapshot['requirements_complete']
                        ? 'تم اعتماد الهوية والشهادة العلمية بنجاح.'
                        : 'تم اعتماد الهوية. سيكتمل التوثيق بعد اعتماد شهادة علمية واحدة على الأقل.')
                    : 'يرجى إعادة رفع مستندات صحيحة.',
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

            $snapshot = VerificationRequirements::syncUserStatus((int) $row->user_id);

            Notify::toUser(
                $row->user_id,
                $approve
                    ? ($snapshot['requirements_complete'] ? 'اكتمل توثيق حسابك' : 'تم اعتماد شهادتك')
                    : 'تم رفض شهادتك',
                $approve
                    ? ($snapshot['requirements_complete']
                        ? 'تم اعتماد الشهادة وأصبحت جميع متطلبات التوثيق مكتملة.'
                        : 'تم اعتماد الشهادة. سيكتمل التوثيق بعد اعتماد الهوية.')
                    : 'تم رفض الشهادة: ' . $row->title,
                'certificate'
            );
        }

        return response()->json(['ok' => true]);
    }
}
