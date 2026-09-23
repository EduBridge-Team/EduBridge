<?php

namespace App\Http\Controllers\Concerns;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

trait WeeklyReportControllerHelpers
{
    private function canViewChild($user, int $childId): bool
    {
        if (!$user) return false;
        if ($user->role === 'admin') return true;
        if ($user->role === 'specialist') {
            return DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
        }
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
    
        return $user->role === 'parent'
            && DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists();
    }
    
    private function normalize($row): array
    {
        $data = (array) $row;
        foreach (['achievements','concerns'] as $field) {
            $value = $data[$field] ?? [];
            if (is_string($value)) {
                $decoded = json_decode($value, true);
                $value = is_array($decoded) ? $decoded : [];
            }
            $data[$field] = array_values(is_array($value) ? $value : []);
        }
        $data['progress_percentage'] = (float) ($data['progress_percentage'] ?? 0);
        return $data;
    }
    
    private function enrich(array $data): array
    {
        $childId = (int) $data['child_id'];
        $weekStart = Carbon::parse($data['week_start'])->startOfDay();
        $weekEnd = Carbon::parse($data['week_end'])->endOfDay();
    
        $data['lessons_total'] = (int) DB::table('lessons')->count();
        if (!isset($data['lessons_completed']) || $data['lessons_completed'] === null) {
            $data['lessons_completed'] = (int) DB::table('progress')
                ->where('child_id', $childId)
                ->where('status', 'done')
                ->whereBetween('completed_at', [$weekStart, $weekEnd])
                ->count();
        }
    
        $homeworks = DB::table('homeworks')->get(['id','assigned_child_ids']);
        $assignedIds = [];
        foreach ($homeworks as $hw) {
            $ids = $hw->assigned_child_ids;
            if (is_string($ids)) {
                $ids = json_decode($ids, true) ?: [];
            }
            if (in_array($childId, array_map('intval', is_array($ids) ? $ids : []), true)) {
                $assignedIds[] = $hw->id;
            }
        }
    
        $data['homework_assigned'] = count($assignedIds);
        $data['homework_submitted'] = $assignedIds
            ? (int) DB::table('homework_submissions')
                ->where('child_id', $childId)
                ->whereIn('homework_id', $assignedIds)
                ->whereBetween('submitted_at', [$weekStart, $weekEnd])
                ->count()
            : 0;
    
        $data['learning_support_meetings_scheduled'] = (int) DB::table('sessions')
            ->where('child_id', $childId)
            ->whereBetween('scheduled_at', [$weekStart, $weekEnd])
            ->count();
    
        $data['learning_support_meetings_attended'] = (int) DB::table('sessions')
            ->where('child_id', $childId)
            ->whereBetween('scheduled_at', [$weekStart, $weekEnd])
            ->where('status', 'done')
            ->count();
    
        return $data;
    }
    
    private function reportQuery()
    {
        return DB::table('weekly_reports as wr')
            ->join('children as c', 'c.id', '=', 'wr.child_id')
            ->leftJoin('users as a', 'a.id', '=', 'wr.author_id')
            ->select('wr.*', 'c.name as child_name', 'a.name as author_name');
    }
    
}
