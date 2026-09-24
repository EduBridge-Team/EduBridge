<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait VerificationUserReviewActions
{
    public function users(Request $request)
    {
        try {
            $query = DB::table('users')
                ->select(
                    'id',
                    'name',
                    'email',
                    'role',
                    'phone',
                    'national_id',
                    'id_document_url',
                    'verification_status',
                    'verification_note',
                    'verified_at',
                    'created_at'
                )
                ->orderByDesc('created_at');

            $status = $request->query('status');
            if ($status && in_array($status, self::STATUSES, true)) {
                $query->where('verification_status', $status);
            }
            if ($request->query('role')) {
                $query->where('role', $request->query('role'));
            }

            return response()->json(['users' => $query->get()]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function reviewUser(Request $request, $id)
    {
        $status = $request->input('status');
        if (!in_array($status, ['verified', 'rejected'], true)) {
            return response()->json(['error' => 'الحالة يجب أن تكون verified أو rejected'], 400);
        }

        try {
            $user = DB::table('users')->where('id', $id)->first();
            if (!$user) {
                return response()->json(['error' => 'المستخدم غير موجود'], 404);
            }

            DB::table('users')->where('id', $id)->update([
                'verification_status' => $status,
                'verification_note' => $request->input('note'),
                'verified_at' => $status === 'verified' ? now() : null,
            ]);

            Notify::toUser(
                $id,
                $status === 'verified' ? 'تم توثيق حسابك' : 'لم يتم توثيق حسابك',
                $status === 'verified'
                    ? 'تم توثيق هويتك بنجاح، يمكنك الآن استخدام كامل الميزات.'
                    : 'تم رفض التوثيق: '
                        . ($request->input('note') ?: 'يرجى إعادة رفع مستندات صحيحة'),
                'verification'
            );

            $fresh = DB::table('users')
                ->select(
                    'id',
                    'name',
                    'email',
                    'role',
                    'verification_status',
                    'verification_note',
                    'verified_at'
                )
                ->find($id);

            return response()->json(['user' => $fresh]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
