<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CareTeamMemberActions
{
    public function addCareTeamMember(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$this->canManage($user, (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $role = (string) $request->input('role', '');
        $userId = (int) $request->input('user_id');
        if (!in_array($role, ['teacher','specialist'], true) || $userId <= 0) {
            return response()->json(['error' => 'المستخدم والدور مطلوبان'], 422);
        }

        if ($role === 'teacher') {
            $request->merge(['teacher_id' => $userId]);

            return $this->addTeacher($request, $childId);
        }

        $request->merge(['specialist_id' => $userId]);

        return $this->addSpecialist($request, $childId);
    }

    public function removeCareTeamMember(Request $request, $childId, $userId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$this->canManage($user, (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $memberRole = DB::table('users')->where('id', $userId)->value('role');
        if ($memberRole === 'specialist') {
            return $this->removeSpecialist($request, $childId, $userId);
        }
        if ($memberRole === 'teacher') {
            return $this->removeTeacher($request, $childId, $userId);
        }
        return response()->json(['error' => 'عضو الفريق غير موجود'], 404);
    }
}
