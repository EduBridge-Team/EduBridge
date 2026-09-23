<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait HomeworkReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = $request->filled('child_id') ? (int) $request->query('child_id') : null;

        if ($childId && !$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $rows = $this->homeworkQuery()->get();

            $ownedChildIds = null;
            if ($user->role === 'parent') {
                $ownedChildIds = DB::table('child_parent')
                    ->where('parent_id', $user->id)
                    ->pluck('child_id')
                    ->map(fn ($id) => (int) $id)
                    ->all();
            }

            $specialistChildIds = null;
            if ($user->role === 'specialist') {
                $specialistChildIds = DB::table('child_specialist')
                    ->where('specialist_id', $user->id)
                    ->pluck('child_id')
                    ->map(fn ($id) => (int) $id)
                    ->all();
            }

            $homeworks = $rows->filter(function ($row) use ($user, $childId, $ownedChildIds, $specialistChildIds) {
                $ids = $row->assigned_child_ids;
                if (is_string($ids)) {
                    $decoded = json_decode($ids, true);
                    $ids = is_array($decoded) ? $decoded : [];
                }
                $ids = array_map('intval', is_array($ids) ? $ids : []);

                if ($childId !== null) {
                    return in_array($childId, $ids, true);
                }
                if ($user->role === 'teacher') {
                    return (int) $row->teacher_id === (int) $user->id;
                }
                if ($user->role === 'parent') {
                    return count(array_intersect($ids, $ownedChildIds ?? [])) > 0;
                }
                if ($user->role === 'specialist') {
                    return count(array_intersect($ids, $specialistChildIds ?? [])) > 0;
                }
                return true;
            })->map(function ($row) use ($user, $childId, $ownedChildIds, $specialistChildIds) {
                $visibleChildIds = $childId !== null
                    ? [$childId]
                    : match ($user->role) {
                        'parent' => $ownedChildIds ?? [],
                        'specialist' => $specialistChildIds ?? [],
                        default => null,
                    };

                return $this->normalize($row, $visibleChildIds);
            })->values();

            return response()->json(['homeworks' => $homeworks]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل الواجبات'], 500);
        }
    }
}
