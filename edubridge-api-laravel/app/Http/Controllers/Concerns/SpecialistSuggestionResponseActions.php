<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SpecialistSuggestionResponseActions
{
    public function accept(Request $request, $id)
    {
        return $this->respond($request, (int) $id, true);
    }

    public function reject(Request $request, $id)
    {
        return $this->respond($request, (int) $id, false);
    }

    private function respond(Request $request, int $id, bool $accept)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $rejectionReason = trim((string) $request->input('reason', ''));

        try {
            $result = DB::transaction(function () use ($user, $id, $accept, $rejectionReason) {
                $suggestion = DB::table('specialist_suggestions')
                    ->where('id', $id)
                    ->lockForUpdate()
                    ->first();

                if (!$suggestion) {
                    return ['status' => 404, 'body' => ['error' => 'الاقتراح غير موجود']];
                }
                if ($user->role === 'specialist' && (int) $suggestion->specialist_id !== (int) $user->id) {
                    return ['status' => 403, 'body' => ['error' => 'هذا الاقتراح ليس موجهاً لك']];
                }
                if ($suggestion->status !== 'pending') {
                    return ['status' => 409, 'body' => ['error' => 'تمت معالجة هذا الاقتراح مسبقاً']];
                }

                DB::table('specialist_suggestions')->where('id', $id)->update([
                    'status' => $accept ? 'accepted' : 'rejected',
                    'rejection_reason' => $accept ? null : ($rejectionReason !== '' ? $rejectionReason : null),
                    'responded_at' => now(),
                    'updated_at' => now(),
                ]);

                if ($accept) {
                    DB::table('child_specialist')->insertOrIgnore([
                        'child_id' => $suggestion->child_id,
                        'specialist_id' => $suggestion->specialist_id,
                        'specialty' => $suggestion->specialty,
                        'assigned_at' => now(),
                        'created_at' => now(),
                    ]);
                }

                return ['status' => 200, 'body' => ['suggestion' => $this->findSuggestion($id)]];
            });

            if (($result['status'] ?? 500) === 200) {
                $suggestion = $result['body']['suggestion'];
                $childName = $suggestion->child_name ?? '';
                $specialistName = $suggestion->specialist_name ?? '';

                Notify::toUser(
                    $suggestion->suggested_by,
                    $accept ? 'تم قبول اقتراح المتابعة' : 'تم رفض اقتراح المتابعة',
                    $specialistName . ($accept ? ' وافق على متابعة ' : ' رفض متابعة ') . $childName . '.',
                    $accept ? 'suggestion_accepted' : 'suggestion_rejected'
                );

                Notify::toChildParents(
                    $suggestion->child_id,
                    $accept ? 'تم تأكيد المختص' : 'تحديث اقتراح المختص',
                    $accept
                        ? 'وافق المختص ' . $specialistName . ' على متابعة ' . $childName . '.'
                        : 'تم رفض اقتراح متابعة ' . $childName . ' من المختص ' . $specialistName . '.',
                    $accept ? 'suggestion_accepted' : 'suggestion_rejected'
                );
            }

            return response()->json($result['body'], $result['status']);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر معالجة الاقتراح'], 500);
        }
    }
}
