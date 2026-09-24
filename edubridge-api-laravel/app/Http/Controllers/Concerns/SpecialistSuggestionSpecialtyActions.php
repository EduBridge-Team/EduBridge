<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait SpecialistSuggestionSpecialtyActions
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
}
