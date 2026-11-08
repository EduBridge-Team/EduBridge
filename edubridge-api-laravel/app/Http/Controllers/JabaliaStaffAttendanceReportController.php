<?php

namespace App\Http\Controllers;

use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaStaffAttendanceReportController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        // The institution may inspect recorded staff attendance; no new school
        // director, deputy, teacher or official-school identity privileges.
        if ($organizationSlug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia'
            || ($actor->role ?? null) !== 'institution'
            || !DB::table('schools')->where('id', $school)
                ->where('organization_id', $org->id)->where('is_active', true)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'from' => ['required', 'date_format:Y-m-d'],
            'to' => ['required', 'date_format:Y-m-d', 'after_or_equal:from'],
        ]);
        $days = CarbonImmutable::parse($data['from'])->diffInDays(CarbonImmutable::parse($data['to']));
        if ($days > 366) {
            return response()->json(['error' => 'أقصى فترة للتقرير 366 يومًا'], 422);
        }

        // Match the current school staff-attendance roster rules: school internal
        // active identities and appointed active management. Do not infer data
        // for any person without recorded attendance.
        $staff = DB::table('users as u')
            ->whereIn('u.role', ['teacher', 'specialist', 'staff', 'director', 'deputy_director'])
            ->where(function ($q) use ($school) {
                $q->whereIn('u.id', DB::table('school_internal_identities')
                    ->where('school_id', $school)->where('is_active', true)->select('user_id'))
                    ->orWhereIn('u.id', DB::table('school_management_assignments')
                        ->where('school_id', $school)->whereNull('ends_at')->select('user_id'));
            })
            ->orderBy('u.name')->orderBy('u.id')
            ->select(['u.id', 'u.name', 'u.role'])
            ->paginate(30);
        $ids = $staff->getCollection()->pluck('id')->all();

        $records = DB::table('school_staff_attendance')
            ->where('school_id', $school)->whereIn('user_id', $ids)
            ->whereBetween('attendance_date', [$data['from'], $data['to']])
            ->select('user_id', 'status', DB::raw('COUNT(*) AS total'))
            ->groupBy('user_id', 'status')->get()->groupBy('user_id');

        $staff->setCollection($staff->getCollection()->map(function ($member) use ($records) {
            $totals = ['present' => 0, 'absent' => 0, 'late' => 0, 'excused' => 0];
            foreach ($records->get($member->id, collect()) as $row) {
                if (array_key_exists($row->status, $totals)) {
                    $totals[$row->status] = (int) $row->total;
                }
            }
            return [
                'user_id' => (int) $member->id,
                'name' => $member->name,
                'role' => $member->role,
                'recorded_days' => array_sum($totals),
                'statuses' => $totals,
            ];
        }));

        return response()->json([
            'school_id' => $school,
            'period' => $data,
            'staff' => $staff,
            'recorded_only' => true,
            'note' => 'تُحسب أيام الحضور المسجلة فقط؛ الأيام بلا سجل لا تعني غيابًا ولا يثبت هذا التقرير الالتزام الوظيفي أو القانوني',
        ]);
    }
}
