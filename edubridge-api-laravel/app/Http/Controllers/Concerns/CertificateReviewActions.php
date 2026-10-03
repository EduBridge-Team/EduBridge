<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use App\Support\VerificationRequirements;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CertificateReviewActions
{
    public function review(Request $request, $id)
    {
        $status = $request->input('status');
        if (!in_array($status, ['verified', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون verified أو rejected'], 400);
        }

        try {
            $certificate = DB::table('certificates')->where('id', $id)->first();
            if (!$certificate) {
                return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            }

            DB::table('certificates')->where('id', $id)->update([
                'status' => $status,
                'note' => $request->input('note'),
            ]);

            $snapshot = VerificationRequirements::syncUserStatus((int) $certificate->user_id);

            if ($status === 'verified' && $snapshot['requirements_complete']) {
                $title = 'اكتمل توثيق حسابك';
                $message = 'تم اعتماد الشهادة: ' . $certificate->title . '، وأصبحت جميع متطلبات التوثيق مكتملة.';
            } elseif ($status === 'verified') {
                $title = 'تم اعتماد شهادتك';
                $message = 'تم اعتماد الشهادة: ' . $certificate->title . '. سيكتمل التوثيق بعد اعتماد الهوية.';
            } else {
                $title = 'تم رفض شهادتك';
                $message = 'تم رفض الشهادة: ' . $certificate->title;
                if ($request->input('note')) {
                    $message .= ' — ' . $request->input('note');
                }
            }

            Notify::toUser(
                $certificate->user_id,
                $title,
                $message,
                'certificate'
            );

            return response()->json([
                'certificate' => DB::table('certificates')->find($id),
                'verification' => $snapshot,
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
