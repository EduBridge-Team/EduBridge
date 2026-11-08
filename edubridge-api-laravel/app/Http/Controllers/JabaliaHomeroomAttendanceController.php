<?php

namespace App\Http\Controllers;

use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class JabaliaHomeroomAttendanceController extends Controller
{
    private function context(Request $request, string $slug): ?object
    {
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if ($slug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia'
            || ($actor->role ?? null) !== 'teacher' || !($actor->id ?? null)) {
            return null;
        }

        // Middleware also validates this; repeat the check at the authorization
        // boundary so a direct controller invocation cannot bypass membership.
        $member = DB::table('organization_user')->where('organization_id', $org->id)
            ->where('user_id', $actor->id)->where('role', 'teacher')
            ->where('is_active', true)->exists();

        return $member ? (object) ['organization' => $org, 'actor' => $actor] : null;
    }

    private function assignedSection(Request $request, string $slug, int $section): ?object
    {
        $scope = $this->context($request, $slug);
        if (!$scope) return null;

        return DB::table('sections as s')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('schools as sch', 'sch.id', '=', 'g.school_id')
            ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
            ->where('s.id', $section)
            ->where('s.homeroom_teacher_id', $scope->actor->id)
            ->whereColumn('y.school_id', 'g.school_id')
            ->where('y.is_current', true)
            ->where('sch.is_active', true)
            ->where('sch.organization_id', $scope->organization->id)
            ->select(['s.id as section_id', 's.name as section_name',
                'g.id as grade_id', 'g.name as grade_name', 'sch.id as school_id'])
            ->first();
    }

    private function today(): string
    {
        return CarbonImmutable::now('Asia/Hebron')->toDateString();
    }

    private function date(Request $request): string
    {
        $data = $request->validate(['date' => ['nullable', 'date_format:Y-m-d']]);
        return $data['date'] ?? $this->today();
    }

    public function sections(Request $request, string $organizationSlug): JsonResponse
    {
        $scope = $this->context($request, $organizationSlug);
        if (!$scope) return response()->json(['error' => 'Not found'], 404);

        $sections = DB::table('sections as s')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('schools as sch', 'sch.id', '=', 'g.school_id')
            ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
            ->where('s.homeroom_teacher_id', $scope->actor->id)
            ->whereColumn('y.school_id', 'g.school_id')
            ->where('y.is_current', true)
            ->where('sch.is_active', true)
            ->where('sch.organization_id', $scope->organization->id)
            ->orderBy('sch.id')->orderBy('g.position')->orderBy('s.id')
            ->select(['s.id as section_id', 's.name as section_name',
                'g.name as grade_name', 'sch.id as school_id', 'sch.name as school_name'])
            ->get();

        return response()->json(['sections' => $sections, 'today' => $this->today()]);
    }

    public function show(Request $request, string $organizationSlug, int $section): JsonResponse
    {
        $row = $this->assignedSection($request, $organizationSlug, $section);
        if (!$row) return response()->json(['error' => 'Not found'], 404);

        $date = $this->date($request);
        // Teachers can inspect recent class rolls, but can only create/mark
        // today's daily roll. No historical editing or medical data access.
        $asDate = CarbonImmutable::createFromFormat('!Y-m-d', $date, 'Asia/Hebron');
        if ($asDate->isAfter(CarbonImmutable::today('Asia/Hebron'))
            || $asDate->isBefore(CarbonImmutable::today('Asia/Hebron')->subDays(30))) {
            return response()->json(['error' => 'التاريخ خارج فترة العرض المسموحة'], 422);
        }
        $session = DB::table('attendance_sessions')->where('section_id', $section)
            ->where('attendance_date', $date)->whereNull('period_number')->first();

        if (!$session) {
            return response()->json([
                'section' => $row, 'date' => $date, 'session' => null,
                'records' => [], 'can_mark' => $date === $this->today(),
            ]);
        }

        $org = $request->attributes->get('organization');
        $records = DB::table('attendance_records as a')
            ->join('children as c', 'c.id', '=', 'a.child_id')
            ->join('student_enrollments as e', function ($join) use ($section) {
                $join->on('e.child_id', '=', 'a.child_id')
                    ->where('e.section_id', '=', $section)->where('e.status', '=', 'active');
            })
            ->where('a.attendance_session_id', $session->id)
            ->where('c.organization_id', $org->id)
            ->orderBy('c.name')
            ->select('a.child_id', 'c.name as child_name', 'a.status', 'a.marked_at')
            ->get()->map(fn ($item) => [
                'child_id' => (int) $item->child_id,
                'child_name' => $item->child_name,
                'status' => $item->status,
                'confirmed' => $item->marked_at !== null,
            ]);

        return response()->json([
            'section' => $row, 'date' => $date,
            'session' => ['id' => (int) $session->id, 'status' => $session->status],
            'records' => $records,
            'can_mark' => $date === $this->today() && $session->status === 'open',
        ]);
    }

    public function start(Request $request, string $organizationSlug, int $section): JsonResponse
    {
        $data = $request->validate(['date' => ['required', 'date_format:Y-m-d']]);
        if ($data['date'] !== $this->today()) {
            return response()->json(['error' => 'يمكن إنشاء حضور اليوم الحالي فقط'], 422);
        }
        return DB::transaction(function () use ($request, $organizationSlug, $section, $data) {
            $row = $this->assignedSection($request, $organizationSlug, $section);
            if (!$row) return response()->json(['error' => 'Not found'], 404);
            DB::table('schools')->where('id', $row->school_id)->lockForUpdate()->first();
            if (!$this->assignedSection($request, $organizationSlug, $section)) {
                return response()->json(['error' => 'Not found'], 404);
            }
            $request->replace([
                'section_id' => $section, 'attendance_date' => $data['date'],
                'teacher_id' => $request->attributes->get('jwt_user')->id,
            ]);
            return app(InstitutionAttendanceController::class)
                ->store($request, $organizationSlug, (int) $row->school_id);
        });
    }

    public function mark(Request $request, string $organizationSlug, int $section, int $session): JsonResponse
    {
        $data = $request->validate([
            'records' => ['required', 'array', 'min:1', 'max:500'],
            'records.*.child_id' => ['required', 'integer', 'distinct'],
            'records.*.status' => ['required', Rule::in(['present', 'absent', 'late', 'excused'])],
        ]);
        return DB::transaction(function () use ($request, $organizationSlug, $section, $session, $data) {
            $row = $this->assignedSection($request, $organizationSlug, $section);
            if (!$row) return response()->json(['error' => 'Not found'], 404);
            DB::table('schools')->where('id', $row->school_id)->lockForUpdate()->first();
            if (!$this->assignedSection($request, $organizationSlug, $section)) {
                return response()->json(['error' => 'Not found'], 404);
            }
            $roll = DB::table('attendance_sessions')->where('id', $session)
                ->where('section_id', $section)->whereNull('period_number')
                ->where('attendance_date', $this->today())->first();
            if (!$roll) return response()->json(['error' => 'Not found'], 404);

            // Teachers cannot close registers, change a past day, or submit notes;
            // the institution remains responsible for authorized corrections.
            $request->replace(['records' => $data['records'], 'close_session' => false]);
            return app(InstitutionAttendanceController::class)
                ->mark($request, $organizationSlug, (int) $row->school_id, $session);
        });
    }
}
