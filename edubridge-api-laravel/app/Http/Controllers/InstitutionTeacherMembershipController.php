<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InstitutionTeacherMembershipController extends Controller
{
    public function index(Request $request, string $organizationSlug): JsonResponse
    {
        $org = $request->attributes->get('organization');
        $members = DB::table('organization_user as ou')
            ->join('users as u', 'u.id', '=', 'ou.user_id')
            ->where('ou.organization_id', $org->id)
            ->where('ou.role', 'teacher')
            ->select('u.id', 'u.name', 'u.email', 'ou.is_active', 'ou.created_at')
            ->orderBy('u.name')->get();

        return response()->json(['teachers' => $members]);
    }

    public function update(Request $request, string $organizationSlug, int $teacher): JsonResponse
    {
        $org = $request->attributes->get('organization');
        $data = $request->validate(['is_active' => ['required', 'boolean']]);
        $enable = (bool) $data['is_active'];

        return DB::transaction(function () use ($org, $teacher, $enable) {
            $member = DB::table('organization_user')
                ->where('organization_id', $org->id)->where('user_id', $teacher)
                ->where('role', 'teacher')->lockForUpdate()->first();
            if (!$member) {
                return response()->json(['error' => 'المعلم غير موجود في المؤسسة'], 404);
            }

            if ($enable) {
                $user = DB::table('users')->where('id', $teacher)->first();
                if (!$user || $user->role !== 'teacher' || !$user->email_verified_at) {
                    return response()->json(['error' => 'يلزم حساب معلم مؤكد البريد لتفعيل العضوية'], 422);
                }
            } else {
                $assigned = DB::table('teacher_assignments as ta')
                    ->join('sections as s', 's.id', '=', 'ta.section_id')
                    ->join('grades as g', 'g.id', '=', 's.grade_id')
                    ->join('schools as school', 'school.id', '=', 'g.school_id')
                    ->where('ta.teacher_id', $teacher)
                    ->where('school.organization_id', $org->id)->exists();
                if ($assigned) {
                    return response()->json([
                        'error' => 'يجب إلغاء تعيينات المعلم من الشعب والمواد قبل تعطيل عضويته.',
                    ], 409);
                }
            }

            DB::table('organization_user')->where('id', $member->id)
                ->update(['is_active' => $enable, 'updated_at' => now()]);
            return response()->json(['teacher_id' => $teacher, 'is_active' => $enable]);
        });
    }
}
