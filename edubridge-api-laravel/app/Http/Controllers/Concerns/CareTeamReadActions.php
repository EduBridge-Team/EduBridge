<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CareTeamReadActions
{
    public function careTeam(Request $request, $childId)
    {
        $childId = (int) $childId;
        $user = $request->attributes->get('jwt_user');

        if (!$this->canView($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }
        if (!DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }

        $members = $this->teachers($childId)
            ->concat($this->specialists($childId))
            ->values();

        return response()->json([
            'care_team' => [
                'child_id' => $childId,
                'members' => $members,
            ],
        ]);
    }

    public function listTeachers(Request $request, $childId)
    {
        $childId = (int) $childId;
        if (!$this->canView($request->attributes->get('jwt_user'), $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        return response()->json(['teachers' => $this->teachers($childId)]);
    }

    public function listSpecialists(Request $request, $childId)
    {
        $childId = (int) $childId;
        if (!$this->canView($request->attributes->get('jwt_user'), $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $all = $this->specialists($childId);
        $learningSupport = $all->firstWhere('specialty', 'learning_support');
        $educational = $all->firstWhere('specialty', 'educational');
        $others = $all->filter(
            fn ($specialist) => !in_array(
                $specialist->specialty,
                ['learning_support','educational'],
                true
            )
        )->values();

        return response()->json([
            'learning_support' => $learningSupport,
            'educational' => $educational,
            'others' => $others,
            'specialists' => $all,
        ]);
    }
}
