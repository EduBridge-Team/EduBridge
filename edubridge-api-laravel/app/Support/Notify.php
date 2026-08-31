<?php

namespace App\Support;

// مساعد موحّد لإنشاء الإشعارات — يستخدمه المتحكّمات لإرسال الإشعارات
use Illuminate\Support\Facades\DB;

class Notify
{
    // إشعار مستخدم واحد
    public static function toUser($userId, string $title, string $message, ?string $type = null): void
    {
        if (!$userId) {
            return;
        }
        try {
            DB::table('notifications')->insert([
                'user_id' => $userId,
                'title' => $title,
                'message' => $message,
                'type' => $type,
            ]);
        } catch (\Exception $e) {
            report($e);
            // الإشعار ثانوي — لا نُفشل الطلب الأساسي بسببه
        }
    }

    // إشعار كل أولياء أمر طفل معيّن
    public static function toChildParents($childId, string $title, string $message, ?string $type = null): void
    {
        try {
            $parentIds = DB::table('child_parent')
                ->where('child_id', $childId)
                ->pluck('parent_id');

            foreach ($parentIds as $pid) {
                self::toUser($pid, $title, $message, $type);
            }
        } catch (\Exception $e) {
            report($e);
        }
    }

    // إشعار أولياء أمر كل الأطفال الذين يطابق نوع إعاقتهم قيمة معيّنة
    public static function toParentsByDisabilityType($disabilityTypeId, string $title, string $message, ?string $type = null): void
    {
        if (!$disabilityTypeId) {
            return;
        }
        try {
            $parentIds = DB::table('child_parent as cp')
                ->join('children as c', 'c.id', '=', 'cp.child_id')
                ->where('c.disability_type_id', $disabilityTypeId)
                ->distinct()
                ->pluck('cp.parent_id');

            foreach ($parentIds as $pid) {
                self::toUser($pid, $title, $message, $type);
            }
        } catch (\Exception $e) {
            report($e);
        }
    }
}
