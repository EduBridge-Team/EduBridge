<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait SpecialistSuggestionWriteActions
{
    public function updateSpecialty(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || $user->role !== 'specialist') {
            return response()->json(['error' => 'هذه العملية متاحة للمختصين فقط'], 403);
        }

        $specialty = trim((string) $request->input('specialty', ''));
        if (!in_array($specialty, self::SPECIALTIES, true)) {
            return response()->json(['error' => 'التخصص غير صالح'], 422);
        }

        if (!Schema::hasColumn('users', 'specialty')) {
            return response()->json(['error' => 'قاعدة البيانات بحاجة إلى ترقية تخصص المختص'], 503);
        }

        $current = DB::table('users')->where('id', $user->id)->value('specialty');
        if ($current && $current !== $specialty) {
            return response()->json([
                'error' => 'لا يمكن تغيير التخصص بعد حفظه. تواصل مع الدعم الفني.',
            ], 409);
        }

        DB::table('users')->where('id', $user->id)->update(['specialty' => $specialty]);

        return response()->json([
            'message' => 'تم حفظ التخصص بنجاح',
            'specialty' => $specialty,
        ]);
    }

    public function store(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['teacher', 'specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح بإنشاء اقتراح متابعة'], 403);
        }

        $specialistId = (int) $request->input('specialist_id');
        $specialty = trim((string) $request->input('specialty', ''));
        $reason = trim((string) $request->input('reason', ''));

        if (!$specialistId || !in_array($specialty, self::SPECIALTIES, true)) {
            return response()->json(['error' => 'specialist_id والتخصص الصحيح مطلوبان'], 422);
        }
        if ($reason === '') {
            return response()->json(['error' => 'سبب الاقتراح مطلوب'], 422);
        }

        $child = DB::table('children')->where('id', $childId)->first();
        if (!$child) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }

        $specialist = DB::table('users')
            ->where('id', $specialistId)
            ->where('role', 'specialist')
            ->first();
        if (!$specialist) {
            return response()->json(['error' => 'المختص غير موجود'], 404);
        }

        $storedSpecialty = $specialist->specialty ?? null;
        if ($storedSpecialty && $storedSpecialty !== $specialty) {
            return response()->json(['error' => 'التخصص المقترح لا يطابق تخصص المختص'], 422);
        }

        $alreadyAssigned = DB::table('child_specialist')
            ->where('child_id', $childId)
            ->where('specialist_id', $specialistId)
            ->where('specialty', $specialty)
            ->exists();
        if ($alreadyAssigned) {
            return response()->json(['error' => 'هذا المختص يتابع الطفل بالفعل بهذا التخصص'], 409);
        }

        $existing = DB::table('specialist_suggestions')
            ->where('child_id', $childId)
            ->where('specialist_id', $specialistId)
            ->where('specialty', $specialty)
            ->where('status', 'pending')
            ->first();
        if ($existing) {
            return response()->json(['suggestion' => $this->findSuggestion($existing->id)], 200);
        }

        $id = DB::table('specialist_suggestions')->insertGetId([
            'child_id' => $childId,
            'specialist_id' => $specialistId,
            'suggested_by' => $user->id,
            'specialty' => $specialty,
            'reason' => $reason,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Notify::toUser(
            $specialistId,
            'اقتراح متابعة جديد',
            'تم اقتراحك لمتابعة الطفل ' . ($child->name ?? '') . '.',
            'specialist_suggestion'
        );

        return response()->json(['suggestion' => $this->findSuggestion($id)], 201);
    }

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

                $status = $accept ? 'accepted' : 'rejected';
                DB::table('specialist_suggestions')->where('id', $id)->update([
                    'status' => $status,
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
