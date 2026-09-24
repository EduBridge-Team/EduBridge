<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SpecialistSuggestionCreateActions
{
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
}
