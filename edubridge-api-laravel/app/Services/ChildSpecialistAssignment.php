<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class ChildSpecialistAssignment
{
    public const SPECIALTIES = ['educational', 'learning_support'];

    public static function assign(int $childId, int $specialistId, string $specialty): array
    {
        return DB::transaction(function () use ($childId, $specialistId, $specialty) {
            if (!in_array($specialty, self::SPECIALTIES, true)) {
                return ['status' => 422, 'error' => 'المتابعة متاحة لمختص تعليمي ومختص دعم تعليمي فقط'];
            }
            // Serialize all assignment paths on the child, including accepting
            // concurrent invitations, without deleting existing team members.
            if (!DB::table('children')->where('id', $childId)->lockForUpdate()->first()) {
                return ['status' => 404, 'error' => 'الطفل غير موجود'];
            }
            $members = DB::table('child_specialist')->where('child_id', $childId)->get();
            foreach ($members as $member) {
                if ((int) $member->specialist_id === $specialistId && $member->specialty === $specialty) {
                    return ['status' => 200, 'added' => false];
                }
                if ($member->specialty === $specialty) {
                    return ['status' => 409, 'error' => 'تم تعيين مختص لهذا النوع بالفعل'];
                }
                if ((int) $member->specialist_id === $specialistId) {
                    return ['status' => 409, 'error' => 'لا يمكن للمختص شغل نوعَي المتابعة لنفس الطفل'];
                }
            }
            if ($members->count() >= 2) {
                return ['status' => 409, 'error' => 'فريق الطفل مكتمل: مختص تعليمي ومختص دعم تعليمي'];
            }
            $specialist = DB::table('users')->where('id', $specialistId)->where('role', 'specialist')->first();
            if (!$specialist || (!empty($specialist->specialty) && $specialist->specialty !== $specialty)) {
                return ['status' => 422, 'error' => 'التخصص لا يطابق تخصص المختص'];
            }
            DB::table('child_specialist')->insert([
                'child_id' => $childId, 'specialist_id' => $specialistId,
                'specialty' => $specialty, 'assigned_at' => now(), 'created_at' => now(),
            ]);
            return ['status' => 200, 'added' => true];
        });
    }
}
