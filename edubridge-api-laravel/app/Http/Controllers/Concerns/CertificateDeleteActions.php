<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CertificateDeleteActions
{
    public function destroy(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');

        try {
            $certificate = DB::table('certificates')->where('id', $id)->first();
            if (!$certificate) {
                return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            }
            if ($me->role !== 'admin' && (int) $certificate->user_id !== (int) $me->id) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            DB::table('certificates')->where('id', $id)->delete();

            $prefix = '/api/private-files/user/' . (int) $certificate->user_id . '/';
            if (is_string($certificate->url) && str_starts_with($certificate->url, $prefix)) {
                $filename = basename(parse_url($certificate->url, PHP_URL_PATH) ?: $certificate->url);

                if (preg_match('/^[A-Za-z0-9._-]+$/', $filename)) {
                    try {
                        R2Storage::delete(
                            R2Storage::privateBucket(),
                            'user-files/' . (int) $certificate->user_id . '/' . $filename
                        );
                    } catch (\Throwable $e) {
                        report($e);
                    }
                }
            }

            return response()->json(['message' => 'تم الحذف']);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
