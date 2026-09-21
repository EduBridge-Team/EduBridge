<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WeeklyReportController extends Controller
{
    private function canViewChild($user, int $childId): bool
    {
        if (!$user) return false;
        if (in_array($user->role, ['teacher','specialist','admin'], true)) return true;

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

        $data['therapy_sessions_scheduled'] = (int) DB::table('sessions')
            ->where('child_id', $childId)
            ->whereBetween('scheduled_at', [$weekStart, $weekEnd])
            ->count();

        $data['therapy_sessions_attended'] = (int) DB::table('sessions')
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

    public function show(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = (int) $request->query('child_id');
        $weekRaw = (string) $request->query('week_start', '');

        if ($childId <= 0 || !$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $weekStart = $weekRaw !== ''
                ? Carbon::parse($weekRaw)->startOfDay()
                : now()->startOfWeek(Carbon::MONDAY)->startOfDay();

            $row = $this->reportQuery()
                ->where('wr.child_id', $childId)
                ->whereDate('wr.week_start', $weekStart->toDateString())
                ->first();

            if (!$row) {
                return response()->json(['report' => null]);
            }

            return response()->json([
                'report' => $this->enrich($this->normalize($row)),
            ]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل التقرير'], 500);
        }
    }

    public function byChild(Request $request, $childId)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = (int) $childId;

        if (!$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $rows = $this->reportQuery()
                ->where('wr.child_id', $childId)
                ->orderByDesc('wr.week_start')
                ->get()
                ->map(fn ($row) => $this->enrich($this->normalize($row)))
                ->values();

            return response()->json(['reports' => $rows]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل التقارير'], 500);
        }
    }

    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['teacher','specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $childId = (int) $request->input('child_id');
        if ($childId <= 0 || !DB::table('children')->where('id', $childId)->exists()) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }

        try {
            $weekStart = Carbon::parse((string) $request->input('week_start'))->startOfDay();
        } catch (\Throwable $e) {
            return response()->json(['error' => 'بداية الأسبوع غير صالحة'], 422);
        }
        $weekEnd = (clone $weekStart)->addDays(6)->endOfDay();

        $progress = (int) $request->input('progress_percentage', 0);
        if ($progress < 0 || $progress > 100) {
            return response()->json(['error' => 'نسبة التقدم يجب أن تكون بين 0 و100'], 422);
        }

        $achievements = $request->input('achievements', []);
        $concerns = $request->input('concerns', []);
        if (!is_array($achievements) || !is_array($concerns)) {
            return response()->json(['error' => 'الإنجازات ونقاط الانتباه يجب أن تكون قوائم'], 422);
        }

        $existing = DB::table('weekly_reports')
            ->where('child_id', $childId)
            ->whereDate('week_start', $weekStart->toDateString())
            ->first();

        $payload = [
            'child_id' => $childId,
            'author_id' => $user->id,
            'week_start' => $weekStart,
            'week_end' => $weekEnd,
            'lessons_completed' => (int) $request->input('lessons_completed', 0),
            'progress_percentage' => $progress,
            'teacher_notes' => $request->input('teacher_notes'),
            'specialist_notes' => $request->input('specialist_notes'),
            'parent_notes' => $request->input('parent_notes'),
            'achievements' => json_encode(array_values($achievements), JSON_UNESCAPED_UNICODE),
            'concerns' => json_encode(array_values($concerns), JSON_UNESCAPED_UNICODE),
            'generated_at' => now(),
            'updated_at' => now(),
        ];

        try {
            if ($existing) {
                DB::table('weekly_reports')->where('id', $existing->id)->update($payload);
                $id = $existing->id;
            } else {
                $id = DB::table('weekly_reports')->insertGetId(array_merge($payload, [
                    'created_at' => now(),
                ]));
            }

            Notify::toChildParents(
                $childId,
                'تقرير أسبوعي جديد',
                'تم تحديث التقرير الأسبوعي للطفل.',
                'weekly_report_created'
            );

            $row = $this->reportQuery()->where('wr.id', $id)->first();
            return response()->json([
                'report' => $this->enrich($this->normalize($row)),
            ], $existing ? 200 : 201);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حفظ التقرير الأسبوعي'], 500);
        }
    }
}
