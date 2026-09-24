<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait HomeworkAssignmentHelpers
{
    private function parseAssignedChildIds($assigned): array
    {
        if (is_string($assigned)) {
            $decoded = json_decode($assigned, true);
            $assigned = is_array($decoded) ? $decoded : [];
        }

        if (!is_array($assigned)) {
            return [];
        }

        return array_values(array_unique(array_filter(array_map('intval', $assigned))));
    }

    private function validateAssignedChildren($user, array $assigned)
    {
        $validChildCount = DB::table('children')->whereIn('id', $assigned)->count();

        if ($validChildCount !== count($assigned)) {
            return response()->json(['error' => 'بعض الأطفال المحددين غير موجودين'], 422);
        }

        if ($user->role === 'specialist') {
            $authorizedCount = DB::table('child_specialist')
                ->whereIn('child_id', $assigned)
                ->where('specialist_id', $user->id)
                ->distinct()
                ->count('child_id');

            if ($authorizedCount !== count($assigned)) {
                return response()->json([
                    'error' => 'يمكنك إسناد الواجبات فقط للأطفال ضمن فريقك',
                ], 403);
            }
        }

        if ($user->role === 'teacher') {
            $authorizedIds = DB::table('children')
                ->whereIn('id', $assigned)
                ->where('assigned_teacher_id', $user->id)
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->all();

            $teamIds = DB::table('child_teacher')
                ->whereIn('child_id', $assigned)
                ->where('teacher_id', $user->id)
                ->pluck('child_id')
                ->map(fn ($id) => (int) $id)
                ->all();

            $authorizedCount = count(array_unique(array_merge($authorizedIds, $teamIds)));

            if ($authorizedCount !== count($assigned)) {
                return response()->json([
                    'error' => 'يمكنك إسناد الواجبات فقط للأطفال المسندين إليك',
                ], 403);
            }
        }

        return null;
    }
}
