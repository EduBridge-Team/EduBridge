<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CareTeamSpecialistActions
{
    public function addSpecialist(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        $specialistId = (int) $request->input('specialist_id');
        $specialty = (string) $request->input('specialty', '');

        $selfClaim = $user
            && $user->role === 'specialist'
            && (int) $user->id === $specialistId;

        if (!$selfClaim && !$this->canManage($user, (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!in_array($specialty, self::SPECIALTIES, true)) {
            return response()->json(['error' => 'التخصص غير صالح'], 422);
        }

        $specialist = $specialistId
            ? DB::table('users')->where('id', $specialistId)->where('role', 'specialist')->first()
            : null;

        if (!$specialist) {
            return response()->json(['error' => 'المختص غير موجود'], 404);
        }
        if (!DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }
        if (!empty($specialist->specialty) && $specialist->specialty !== $specialty) {
            return response()->json(['error' => 'التخصص لا يطابق تخصص المختص'], 422);
        }

        $result = \App\Services\ChildSpecialistAssignment::assign((int) $childId, $specialistId, $specialty);
        if (isset($result['error'])) return response()->json(['error' => $result['error']], $result['status']);
        if (!$result['added']) return $this->listSpecialists($request, $childId);

        Notify::toUser(
            $specialistId,
            'تمت إضافتك لفريق دعم تعليمي',
            'تم تعيينك ضمن فريق دعم تعليمي طفل.',
            'care_team_assigned'
        );

        return $this->listSpecialists($request, $childId);
    }

    public function removeSpecialist(Request $request, $childId, $specialistId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if ($user->role === 'specialist') {
            if (
                (int) $user->id !== (int) $specialistId
                || !$this->canManage($user, (int) $childId)
            ) {
                return response()->json([
                    'error' => 'يمكن للمختص إزالة نفسه فقط من فريق الطفل',
                ], 403);
            }
        } elseif ($user->role !== 'admin') {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::table('child_specialist')
            ->where('child_id', $childId)
            ->where('specialist_id', $specialistId)
            ->delete();

        return response()->json(['ok' => true]);
    }
}
