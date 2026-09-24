<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait VerificationChildReviewActions
{
    public function children(Request $request)
    {
        try {
            $query = DB::table('children')
                ->select(
                    'id',
                    'name',
                    'child_national_id',
                    'guardian_national_id',
                    'guardian_id_document_url',
                    'kinship_document_url',
                    'doc_verification_status',
                    'doc_verification_note',
                    'created_at'
                )
                ->orderByDesc('created_at');

            $status = $request->query('status');
            if ($status && in_array($status, self::STATUSES, true)) {
                $query->where('doc_verification_status', $status);
            }

            return response()->json(['children' => $query->get()]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function reviewChild(Request $request, $id)
    {
        $status = $request->input('status');
        if (!in_array($status, ['verified', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون verified أو rejected'], 400);
        }

        try {
            $child = DB::table('children')->where('id', $id)->first();
            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            DB::table('children')->where('id', $id)->update([
                'doc_verification_status' => $status,
                'doc_verification_note' => $request->input('note'),
            ]);

            Notify::toChildParents(
                $id,
                $status === 'verified' ? 'تم توثيق بيانات الطفل' : 'لم يتم توثيق بيانات الطفل',
                $status === 'verified'
                    ? 'تم التحقق من هوية وصلة قرابة الطفل ' . ($child->name ?? '') . ' بنجاح.'
                    : 'تم رفض توثيق بيانات الطفل ' . ($child->name ?? '') . ': '
                        . ($request->input('note') ?: 'يرجى إعادة رفع المستندات'),
                'verification'
            );

            return response()->json([
                'child' => DB::table('children')->find($id),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
