<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConsultationCreateActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        $childId = $request->input('child_id');
        $title = trim((string) $request->input('title'));
        if (!$childId || $title === '') {
            return response()->json(['error' => 'معرّف الطفل وعنوان الحالة مطلوبان'], 400);
        }
        if (!$user || !in_array($user->role, ['parent', 'teacher', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            if (!DB::table('children')->where('id', $childId)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }
            if (!$this->canAccessChild($user, (int) $childId)) {
                return response()->json(['error' => 'لا تملك صلاحية على هذا الطفل'], 403);
            }

            $specialistId = $request->input('specialist_id');
            if ($specialistId && $user->role !== 'admin') {
                return response()->json(['error' => 'إسناد المختص مسبقاً متاح للأدمن فقط'], 403);
            }
            if (
                $specialistId
                && !DB::table('users')->where('id', $specialistId)->where('role', 'specialist')->exists()
            ) {
                return response()->json(['error' => 'المختص غير موجود'], 404);
            }

            $id = DB::table('consultations')->insertGetId([
                'child_id' => $childId,
                'requester_id' => $user->id,
                'specialist_id' => $specialistId ?: null,
                'title' => $title,
                'description' => $request->input('description'),
                'status' => $specialistId ? 'assigned' : 'open',
            ]);

            if ($specialistId) {
                Notify::toUser(
                    $specialistId,
                    'طلب دراسة حالة جديد',
                    'تم إسناد دراسة حالة إليك: ' . $title,
                    'consultation'
                );
            }

            return response()->json([
                'consultation' => DB::table('consultations')->find($id),
            ], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
