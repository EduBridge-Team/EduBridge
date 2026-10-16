<?php

namespace App\Http\Controllers;

use App\Support\ChildAccess;
use App\Support\LessonVisibility;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LessonRecommendationController extends Controller
{
    /**
     * Recommend an existing child-visible lesson to an assigned child's parents.
     * Never change the lesson audience or the child's progress.
     */
    public function store(Request $request, int $id): JsonResponse
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || $user->role !== 'specialist') {
            return response()->json(['error' => 'غير مسموح بهذا الإجراء'], 403);
        }

        $data = $request->validate([
            'child_id' => ['required', 'integer', 'min:1'],
        ]);
        $childId = (int) $data['child_id'];

        if (!ChildAccess::allowed($user, $childId)) {
            return response()->json(['error' => 'لا يمكنك اقتراح درس لهذا الطفل'], 403);
        }

        $child = DB::table('children')->where('id', $childId)->first();
        $lesson = DB::table('lessons')->where('id', $id)->first();
        if (!$child || !$lesson) {
            return response()->json(['error' => 'الطفل أو الدرس غير موجود'], 404);
        }

        if (!LessonVisibility::allowed($user, $id) ||
            !$this->isVisibleToChild($lesson, $child)) {
            return response()->json(['error' => 'هذا الدرس غير متاح للطفل المحدد'], 422);
        }

        $parentIds = DB::table('child_parent')
            ->where('child_id', $childId)
            ->distinct()
            ->pluck('parent_id');
        if ($parentIds->isEmpty()) {
            return response()->json(['error' => 'لا يوجد ولي أمر مرتبط بهذا الطفل لإرسال الاقتراح'], 422);
        }

        $title = 'درس مقترح لطفلك';
        $message = mb_substr(
            'اقترح المختص درس «' . $lesson->title . '» للطفل ' . $child->name .
            '. يمكنك فتح مكتبة الدروس للاطلاع عليه.',
            0,
            245
        );

        try {
            $sent = DB::transaction(function () use ($parentIds, $title, $message) {
                $created = 0;
                foreach ($parentIds as $parentId) {
                    // A repeated tap must not send the same recommendation twice in a day.
                    $existing = DB::table('notifications')
                        ->where('user_id', $parentId)
                        ->where('type', 'lesson_recommendation')
                        ->where('message', $message)
                        ->where('created_at', '>=', now()->subDay())
                        ->exists();
                    if ($existing) {
                        continue;
                    }
                    DB::table('notifications')->insert([
                        'user_id' => $parentId,
                        'title' => $title,
                        'message' => $message,
                        'type' => 'lesson_recommendation',
                        'created_at' => now(),
                    ]);
                    $created++;
                }
                return $created;
            });

            return response()->json([
                'message' => $sent > 0
                    ? 'تم إرسال اقتراح الدرس إلى ولي الأمر'
                    : 'سبق إرسال هذا الاقتراح خلال آخر 24 ساعة',
                'sent' => $sent,
            ], $sent > 0 ? 201 : 200);
        } catch (\Throwable $error) {
            report($error);
            return response()->json(['error' => 'تعذّر إرسال اقتراح الدرس'], 500);
        }
    }

    private function isVisibleToChild(object $lesson, object $child): bool
    {
        $target = $lesson->target_type ?? 'everyone';
        if ($target === 'everyone') {
            return true;
        }
        if ($target === 'byDisability') {
            return $lesson->disability_type_id !== null &&
                (int) $lesson->disability_type_id === (int) $child->disability_type_id;
        }
        if ($target === 'specificChildren') {
            $raw = $lesson->target_child_ids ?? [];
            $ids = is_string($raw) ? json_decode($raw, true) : $raw;
            return is_array($ids) && in_array((int) $child->id, array_map('intval', $ids), true);
        }
        // A parent-only lesson is not a lesson assigned to the child.
        return false;
    }
}
