<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaTeacherHistoryController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school, int $teacher): JsonResponse
    {
        $organization = $request->attributes->get('organization');
        if (!$organization || $organization->slug !== 'jabalia' || $organizationSlug !== 'jabalia') {
            return response()->json(['error' => 'هذه الخدمة خاصة بجمعية جباليا'], 404);
        }

        if (!DB::table('schools')->where('id', $school)->where('organization_id', $organization->id)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        if (!DB::table('organization_user')->where('organization_id', $organization->id)
            ->where('user_id', $teacher)->where('role', 'teacher')->exists()) {
            return response()->json(['error' => 'المعلم غير موجود في المؤسسة'], 404);
        }

        $profile = DB::table('jabalia_teacher_profiles')
            ->where('organization_id', $organization->id)->where('teacher_id', $teacher)->first();

        $history = DB::table('jabalia_teacher_assignment_history as h')
            ->leftJoin('sections as s', 's.id', '=', 'h.section_id')
            ->leftJoin('subjects as sub', 'sub.id', '=', 'h.subject_id')
            ->where('h.organization_id', $organization->id)
            ->where('h.school_id', $school)
            ->where('h.teacher_id', $teacher)
            ->select('h.id', 'h.school_id', 'h.teacher_id', 'h.section_id', 'h.subject_id',
                'h.starts_on', 'h.ends_on', 'h.status', 'h.reason', 'h.recorded_by',
                's.name as section_name', 'sub.name as subject_name', 'h.created_at')
            ->orderByDesc('h.starts_on')->orderByDesc('h.id')->paginate(30);

        return response()->json(['profile' => $profile, 'history' => $history]);
    }
}
