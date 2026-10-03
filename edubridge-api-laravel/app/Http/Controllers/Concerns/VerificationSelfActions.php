<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use App\Support\VerificationRequirements;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait VerificationSelfActions
{
    public function submitMine(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        $updates = [];
        $previousIdentityUrl = null;
        if ($request->has('national_id')) {
            $nationalId = trim((string) $request->input('national_id'));
            $updates['national_id'] = $nationalId !== '' ? $nationalId : null;
        }
        if ($request->has('id_document_url')) {
            $url = trim((string) $request->input('id_document_url'));
            $currentUrl = (string) (DB::table('users')
                ->where('id', $user->id)
                ->value('id_document_url') ?? '');
            $previousIdentityUrl = $currentUrl !== '' ? $currentUrl : null;

            if ($url !== '') {
                $expectedPrefix = '/api/private-files/user/' . (int) $user->id . '/';

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

        $updates['identity_status'] = 'pending';
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
                    'identity_status',
                    'verification_status'
                )
                ->find($user->id);

            if (
                $request->has('id_document_url')
                && $previousIdentityUrl
                && $previousIdentityUrl !== (string) ($fresh->id_document_url ?? '')
            ) {
                $this->deleteUnusedIdentityFile($previousIdentityUrl, (int) $user->id);
            }

            $snapshot = VerificationRequirements::snapshot($fresh);

            return response()->json([
                'user' => $fresh,
                'verification' => $snapshot,
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    private function deleteUnusedIdentityFile(string $url, int $userId): void
    {
        $prefix = '/api/private-files/user/' . $userId . '/';
        if (!str_starts_with($url, $prefix)) {
            return;
        }

        $stillUsed = DB::table('users')->where('id_document_url', $url)->exists()
            || DB::table('certificates')->where('url', $url)->exists()
            || DB::table('children')->where('guardian_id_document_url', $url)->exists()
            || DB::table('children')->where('kinship_document_url', $url)->exists();

        if ($stillUsed) {
            return;
        }

        $filename = basename(parse_url($url, PHP_URL_PATH) ?: $url);
        if (!preg_match('/^[A-Za-z0-9._-]+$/', $filename)) {
            return;
        }

        try {
            R2Storage::delete(
                R2Storage::privateBucket(),
                'user-files/' . $userId . '/' . $filename
            );
        } catch (\Throwable $e) {
            report($e);
        }
    }

    public function myStatus(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $row = DB::table('users')
            ->select(
                'id',
                'role',
                'verification_status',
                'identity_status',
                'verification_note',
                'national_id',
                'id_document_url',
                'verified_at'
            )
            ->find($user->id);

        if (!$row) {
            return response()->json(['error' => 'المستخدم غير موجود'], 404);
        }

        $snapshot = VerificationRequirements::snapshot($row);

        return response()->json(['verification' => array_merge((array) $row, $snapshot)]);
    }
}
