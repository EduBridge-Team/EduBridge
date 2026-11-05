<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaSchoolCalendarController extends Controller
{
    private function scoped(Request $request, string $slug, int $school): ?object
    {
        $org = $request->attributes->get('organization');
        if ($slug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia') return null;
        return DB::table('schools')->where('id', $school)
            ->where('organization_id', $org->id)->first();
    }

    private function hasAttendance(int $school, string $day): bool
    {
        return DB::table('attendance_sessions as a')
            ->join('sections as s', 's.id', '=', 'a.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('g.school_id', $school)
            ->whereDate('a.attendance_date', $day)->exists();
    }

    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->scoped($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $org = $request->attributes->get('organization');
        return response()->json([
            'days' => DB::table('jabalia_school_closure_days')
                ->where('organization_id', $org->id)->where('school_id', $school)
                ->orderByDesc('closed_on')->limit(200)
                ->get(['id', 'closed_on', 'reason', 'created_at']),
            'recent_changes' => DB::table('jabalia_school_closure_events')
                ->where('organization_id', $org->id)->where('school_id', $school)
                ->orderByDesc('id')->limit(50)
                ->get(['id', 'closed_on', 'action', 'reason', 'actor_id', 'created_at']),
        ]);
    }

    public function store(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->scoped($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $data = $request->validate([
            'closed_on' => ['required', 'date_format:Y-m-d'],
            'reason' => ['required', 'string', 'min:3', 'max:250'],
        ]);
        $reason = trim($data['reason']);
        if (mb_strlen($reason) < 3) {
            return response()->json(['error' => 'سبب الإغلاق مطلوب'], 422);
        }
        $org = $request->attributes->get('organization');
        $actorId = $request->attributes->get('jwt_user')?->id ?? $request->user()?->id;

        return DB::transaction(function () use ($school, $org, $actorId, $data, $reason) {
            // The same school lock is used before attendance-session creation.
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            $existing = DB::table('jabalia_school_closure_days')
                ->where('school_id', $school)->where('closed_on', $data['closed_on'])->exists();
            if ($existing) {
                return response()->json(['error' => 'اليوم مغلق مسبقًا'], 409);
            }
            if ($this->hasAttendance($school, $data['closed_on'])) {
                return response()->json([
                    'error' => 'يجب تسوية سجلات الحضور الموجودة قبل اعتماد يوم الإغلاق',
                ], 409);
            }
            $id = DB::table('jabalia_school_closure_days')->insertGetId([
                'organization_id' => $org->id, 'school_id' => $school,
                'closed_on' => $data['closed_on'], 'reason' => $reason,
                'created_by' => $actorId, 'created_at' => now(), 'updated_at' => now(),
            ]);
            DB::table('jabalia_school_closure_events')->insert([
                'organization_id' => $org->id, 'school_id' => $school,
                'closed_on' => $data['closed_on'], 'reason' => $reason,
                'action' => 'created', 'actor_id' => $actorId, 'created_at' => now(),
            ]);
            return response()->json([
                'day' => DB::table('jabalia_school_closure_days')->where('id', $id)->first(),
            ], 201);
        });
    }

    public function destroy(Request $request, string $organizationSlug, int $school, int $closure): JsonResponse
    {
        if (!$this->scoped($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $org = $request->attributes->get('organization');
        $actorId = $request->attributes->get('jwt_user')?->id ?? $request->user()?->id;

        return DB::transaction(function () use ($school, $closure, $org, $actorId) {
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            $row = DB::table('jabalia_school_closure_days')
                ->where('id', $closure)->where('organization_id', $org->id)
                ->where('school_id', $school)->first();
            if (!$row) {
                return response()->json(['error' => 'اليوم غير موجود'], 404);
            }
            if ($this->hasAttendance($school, $row->closed_on)) {
                return response()->json(['error' => 'لا يمكن إعادة فتح يوم له سجلات حضور'], 409);
            }
            DB::table('jabalia_school_closure_days')->where('id', $row->id)
                ->where('school_id', $school)->delete();
            DB::table('jabalia_school_closure_events')->insert([
                'organization_id' => $org->id, 'school_id' => $school,
                'closed_on' => $row->closed_on, 'reason' => $row->reason,
                'action' => 'removed', 'actor_id' => $actorId, 'created_at' => now(),
            ]);
            return response()->json(['removed' => true]);
        });
    }
}
