<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
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

            Notify::toUser(
                $certificate->user_id,
                $status === 'verified' ? 'تم اعتماد شهادتك' : 'تم رفض شهادتك',
                ($status === 'verified' ? 'تم اعتماد الشهادة: ' : 'تم رفض الشهادة: ')
                    . $certificate->title,
                'certificate'
            );

            return response()->json([
                'certificate' => DB::table('certificates')->find($id),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
