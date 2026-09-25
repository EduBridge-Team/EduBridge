<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait VerificationSelfActions
{
    public function submitMine(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        $updates = [];
        if ($request->has('national_id')) {
            $nationalId = trim((string) $request->input('national_id'));
            $updates['national_id'] = $nationalId !== '' ? $nationalId : null;
        }
        if ($request->has('id_document_url')) {
            $url = trim((string) $request->input('id_document_url'));
            if ($url !== '') {
                $expectedPrefix = '/api/private-files/user/' . (int) $user->id . '/';
                $currentUrl = (string) (DB::table('users')
                    ->where('id', $user->id)
                    ->value('id_document_url') ?? '');

                if (!str_starts_with($url, $expectedPrefix) && $url !== $currentUrl) {
                    return response()->json([
                        'error' => 'ملف الهوية يجب أن يكون مرفوعاً من حسابك عبر التخزين الآمن',
                    ], 422);
                }
            }
            $updates['id_document_url'] = $url !== '' ? $url : null;
        }

        if (empty($updates)) {
            return response()->json(['error' => 'لا توجد بيانات لتحديثها'], 400);
        }

        $updates['verification_status'] = 'pending';
        $updates['verification_note'] = null;
        $updates['verified_at'] = null;

        try {
            DB::table('users')->where('id', $user->id)->update($updates);

            $fresh = DB::table('users')
                ->select(
                    'id',
                    'name',
                    'email',
                    'role',
                    'national_id',
                    'id_document_url',
                    'verification_status'
                )
                ->find($user->id);

            return response()->json(['user' => $fresh]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function myStatus(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $row = DB::table('users')
            ->select(
                'verification_status',
                'verification_note',
                'national_id',
                'id_document_url',
                'verified_at'
            )
            ->find($user->id);

        return response()->json(['verification' => $row]);
    }
}
