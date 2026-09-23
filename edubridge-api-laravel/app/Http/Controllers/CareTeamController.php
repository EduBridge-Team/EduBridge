<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CareTeamController extends Controller
{
    private const SPECIALTIES = ['educational','learning_support','communication_support','learning_behavior'];

    private function canView($user, int $childId): bool
    {
        if (!$user) return false;
        if ($user->role === 'admin') return true;

        if ($user->role === 'teacher') {
            return DB::table('children')
                ->where('id', $childId)
                ->where('assigned_teacher_id', $user->id)
                ->exists()
                || DB::table('child_teacher')
                    ->where('child_id', $childId)
                    ->where('teacher_id', $user->id)
                    ->exists();
        }

        if ($user->role === 'specialist') {
            return DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
        }

        return $user->role === 'parent'
            && DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists();
    }

    private function canManage($user, int $childId): bool
    {
        if (!$user) return false;
        if ($user->role === 'admin') return true;

        return $user->role === 'specialist'
            && DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
    }

    private function teachers(int $childId)
    {
        return DB::table('child_teacher as ct')
            ->join('users as u', 'u.id', '=', 'ct.teacher_id')
            ->where('ct.child_id', $childId)
            ->select(
                'u.id',
                'u.id as user_id',
                'u.name',
                'u.email',
                DB::raw("'teacher' as role"),
                'ct.subject',
                'ct.assigned_at'
            )
            ->orderBy('u.name')
            ->get();
    }

    private function specialists(int $childId)
    {
        return DB::table('child_specialist as cs')
            ->join('users as u', 'u.id', '=', 'cs.specialist_id')
            ->where('cs.child_id', $childId)
            ->select(
                'u.id',
                'u.id as user_id',
                'u.name',
                'u.email',
                DB::raw("'specialist' as role"),
                'cs.specialty',
                'cs.assigned_at'
            )
            ->orderBy('u.name')
            ->get();
    }

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

    public function listTeachers(Request $request, $childId)
    {
        $childId = (int) $childId;
        if (!$this->canView($request->attributes->get('jwt_user'), $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        return response()->json(['teachers' => $this->teachers($childId)]);
    }

    public function addTeacher(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$this->canManage($user, (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $teacherId = (int) $request->input('teacher_id');
        if (!$teacherId || !DB::table('users')->where('id', $teacherId)->where('role', 'teacher')->exists()) {
            return response()->json(['error' => 'المعلّم غير موجود'], 404);
        }

        if (!DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }

        DB::table('child_teacher')->insertOrIgnore([
            'child_id' => $childId,
            'teacher_id' => $teacherId,
            'subject' => $request->input('subject'),
            'assigned_at' => now(),
            'created_at' => now(),
        ]);

        Notify::toUser($teacherId, 'تمت إضافتك لفريق دعم تعليمي',
            'تم تعيينك ضمن فريق دعم تعليمي طفل.', 'care_team_assigned');

        return response()->json(['teachers' => $this->teachers((int) $childId)], 201);
    }

    public function removeTeacher(Request $request, $childId, $teacherId)
    {
        if (!$this->canManage($request->attributes->get('jwt_user'), (int) $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::table('child_teacher')
            ->where('child_id', $childId)
            ->where('teacher_id', $teacherId)
            ->delete();

        return response()->json(['ok' => true]);
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
        $others = $all->filter(fn ($s) =>
            !in_array($s->specialty, ['learning_support','educational'], true)
        )->values();

        return response()->json([
            'learning_support' => $learningSupport,
            'educational' => $educational,
            'others' => $others,
            'specialists' => $all,
        ]);
    }

    public function addSpecialist(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        $specialistId = (int) $request->input('specialist_id');
        $specialty = (string) $request->input('specialty', '');

        // المختص يستطيع أخذ طفل من قائمة الانتظار لنفسه فقط.
        // تعيين مختص آخر يتطلب صلاحية إدارة فريق الطفل.
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

        if ($selfClaim && DB::table('child_specialist')
            ->where('child_id', $childId)
            ->where('specialty', $specialty)
            ->where('specialist_id', '<>', $specialistId)
            ->exists()) {
            return response()->json(['error' => 'تم تعيين مختص لهذا النوع بالفعل'], 409);
        }

        DB::table('child_specialist')->insertOrIgnore([
            'child_id' => $childId,
            'specialist_id' => $specialistId,
            'specialty' => $specialty,
            'assigned_at' => now(),
            'created_at' => now(),
        ]);

        Notify::toUser($specialistId, 'تمت إضافتك لفريق دعم تعليمي',
            'تم تعيينك ضمن فريق دعم تعليمي طفل.', 'care_team_assigned');

        return $this->listSpecialists($request, $childId);
    }

    public function removeSpecialist(Request $request, $childId, $specialistId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if ($user->role === 'specialist') {
            if ((int) $user->id !== (int) $specialistId
                || !$this->canManage($user, (int) $childId)) {
                return response()->json(['error' => 'يمكن للمختص إزالة نفسه فقط من فريق الطفل'], 403);
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
