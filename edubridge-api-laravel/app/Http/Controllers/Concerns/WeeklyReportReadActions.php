<?php

namespace App\Http\Controllers\Concerns;

use Carbon\Carbon;
use Illuminate\Http\Request;

trait WeeklyReportReadActions
{
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
}
