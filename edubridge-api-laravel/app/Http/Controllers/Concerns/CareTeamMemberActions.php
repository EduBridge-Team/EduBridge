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

        DB::transaction(function () use ($childId, $userId) {
            DB::table('child_teacher')
                ->where('child_id', $childId)
                ->where('teacher_id', $userId)
                ->delete();

            DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $userId)
                ->delete();
        });

        return response()->json(['ok' => true]);
    }
}
