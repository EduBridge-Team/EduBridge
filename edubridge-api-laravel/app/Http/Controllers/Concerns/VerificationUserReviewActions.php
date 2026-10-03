<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use App\Support\VerificationRequirements;
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
                    'identity_status',
                    'verification_status',
                    'verification_note',
                    'verified_at',
                    'created_at'
                )
                ->whereIn('role', ['teacher', 'specialist'])
                ->whereNotNull('id_document_url')
                ->where('id_document_url', '!=', '')
                ->orderByDesc('created_at');

            $status = $request->query('status');
            if ($status && in_array($status, self::STATUSES, true)) {
                $query->where('verification_status', $status);
            }
            if ($request->query('role')) {
                $query->where('role', $request->query('role'));
            }

            $users = $query->get()->map(function ($user) {
                return array_merge((array) $user, VerificationRequirements::snapshot($user));
            })->values();

            return response()->json(['users' => $users]);
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

            if (!in_array($user->role, ['teacher', 'specialist'], true) || !trim((string) ($user->id_document_url ?? ''))) {
                return response()->json(['error' => 'مراجعة الحساب متاحة للمعلمين والمختصين بعد رفع الهوية'], 422);
            }

            DB::table('users')->where('id', $id)->update([
                'identity_status' => $status,
                'verification_note' => $request->input('note'),
            ]);

            $snapshot = VerificationRequirements::syncUserStatus((int) $id);

            if ($status === 'rejected') {
                $title = 'لم يتم اعتماد هويتك';
                $message = 'تم رفض الهوية: '
                    . ($request->input('note') ?: 'يرجى إعادة رفع مستندات صحيحة');
            } elseif ($snapshot['requirements_complete']) {
                $title = 'تم توثيق حسابك';
                $message = 'تم اعتماد الهوية والشهادة العلمية، ويمكنك الآن استخدام كامل الميزات.';
            } else {
                $title = 'تم اعتماد هويتك';
                $message = 'تم اعتماد الهوية. سيكتمل توثيق الحساب بعد اعتماد شهادة علمية واحدة على الأقل.';
            }

            Notify::toUser($id, $title, $message, 'verification');

            $fresh = DB::table('users')
                ->select(
                    'id',
                    'name',
                    'email',
                    'role',
                    'identity_status',
                    'verification_status',
                    'verification_note',
                    'verified_at'
                )
                ->find($id);

            return response()->json([
                'user' => array_merge((array) $fresh, $snapshot),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
