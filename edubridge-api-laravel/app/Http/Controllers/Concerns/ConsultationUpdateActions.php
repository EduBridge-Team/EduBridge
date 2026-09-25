<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConsultationUpdateActions
{
    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $consultation = DB::table('consultations')->where('id', $id)->first();
            if (!$consultation) {
                return response()->json(['error' => 'الاستشارة غير موجودة'], 404);
            }

            $updates = [];

            if ($user->role === 'specialist') {
                $assignedToMe = (int) ($consultation->specialist_id ?? 0) === (int) $user->id;

                if ($request->boolean('claim')) {
                    if ($consultation->specialist_id !== null || $consultation->status !== 'open') {
                        return response()->json(['error' => 'الحالة غير متاحة للاستلام'], 409);
                    }

                    $updates['specialist_id'] = $user->id;
                    $updates['status'] = 'in_progress';
                    $assignedToMe = true;
                }

                if ($request->has('status') && !$assignedToMe) {
                    return response()->json(['error' => 'غير مصرّح بتعديل هذه الحالة'], 403);
                }
            }

            if ($request->has('status')) {
                $status = $request->input('status');
                if (!in_array($status, ['open', 'assigned', 'in_progress', 'closed'], true)) {
                    return response()->json(['error' => 'الحالة غير صالحة'], 400);
                }

                $updates['status'] = $status;
            }

            if (!empty($updates)) {
                DB::table('consultations')->where('id', $id)->update($updates);
            }

            return response()->json([
                'consultation' => DB::table('consultations')->find($id),
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
