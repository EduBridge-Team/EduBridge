<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class JabaliaTeacherSchoolTransferController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school, int $teacher): JsonResponse
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $transfers = DB::table('jabalia_teacher_school_transfers as t')
            ->join('schools as source', 'source.id', '=', 't.from_school_id')
            ->join('schools as destination', 'destination.id', '=', 't.to_school_id')
            ->where('t.organization_id', $org->id)->where('t.teacher_id', $teacher)
            ->where(function ($query) use ($school) {
                $query->where('t.from_school_id', $school)->orWhere('t.to_school_id', $school);
            })->select('t.id', 't.effective_on', 't.reason', 't.from_school_id',
                't.to_school_id', 'source.name as from_school_name',
                'destination.name as to_school_name', 't.created_at')
            ->orderByDesc('t.effective_on')->orderByDesc('t.id')->paginate(30);
        return response()->json(['transfers' => $transfers]);
    }

    public function store(Request $request, string $organizationSlug, int $school, int $teacher): JsonResponse
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $data = $request->validate([
            'to_school_id' => ['required', 'integer', 'different:from_school_id'],
            'effective_on' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            'reason' => ['nullable', 'string', 'max:255'],
        ]);
        $destination = (int) $data['to_school_id'];
        if ($destination === $school || !DB::table('schools')->where('id', $destination)
            ->where('organization_id', $org->id)->exists()) {
            throw ValidationException::withMessages(['to_school_id' => 'يجب اختيار مدرسة أخرى تابعة للمؤسسة نفسها']);
        }

        return DB::transaction(function () use ($org, $school, $teacher, $destination, $data, $request) {
            DB::table('users')->where('id', $teacher)->lockForUpdate()->first();
            if (DB::table('jabalia_teacher_school_transfers')
                ->where('organization_id', $org->id)->where('teacher_id', $teacher)
                ->where('from_school_id', $school)->where('to_school_id', $destination)
                ->where('effective_on', $data['effective_on'])->exists()) {
                return response()->json(['error' => 'تم تسجيل هذا النقل مسبقًا'], 409);
            }
            $futureActiveHistory = DB::table('jabalia_teacher_assignment_history')
                ->where('organization_id', $org->id)->where('teacher_id', $teacher)
                ->where('school_id', $school)->where('status', 'active')
                ->whereNull('ends_on')->where('starts_on', '>', $data['effective_on'])->exists();
            if ($futureActiveHistory) {
                return response()->json(['error' => 'تاريخ النقل يسبق تاريخ بدء أحد التكليفات الحالية'], 422);
            }
            $assignments = DB::table('teacher_assignments as ta')
                ->join('sections as s', 's.id', '=', 'ta.section_id')
                ->join('grades as g', 'g.id', '=', 's.grade_id')
                ->join('subjects as sub', 'sub.id', '=', 'ta.subject_id')
                ->where('g.school_id', $school)->where('sub.school_id', $school)
                ->where('ta.teacher_id', $teacher)
                ->select('ta.id', 'ta.section_id', 'ta.subject_id')->get();
            // Do not leave lessons referencing assignments that this transfer
            // will remove. Administrators must first reschedule or remove them.
            foreach ($assignments as $assignment) {
                if (DB::table('timetable_entries')
                    ->where('school_id', $school)
                    ->where('teacher_id', $teacher)
                    ->where('section_id', $assignment->section_id)
                    ->where('subject_id', $assignment->subject_id)->exists()) {
                    return response()->json([
                        'error' => 'لا يمكن نقل المعلم قبل معالجة حصصه المجدولة في المدرسة الحالية',
                    ], 409);
                }
            }
            // A transfer does not create assignments in the destination school.
            // The school administrator can subsequently assign subjects and sections.
            foreach ($assignments as $assignment) {
                $history = DB::table('jabalia_teacher_assignment_history')
                    ->where('organization_id', $org->id)->where('school_id', $school)
                    ->where('teacher_id', $teacher)->where('section_id', $assignment->section_id)
                    ->where('subject_id', $assignment->subject_id)->where('status', 'active')
                    ->whereNull('ends_on');
                if ($history->exists()) {
                    $history->update([
                        'ends_on' => $data['effective_on'], 'status' => 'ended',
                        'reason' => 'نقل المعلم إلى مدرسة أخرى', 'updated_at' => now(),
                    ]);
                } else {
                    DB::table('jabalia_teacher_assignment_history')->insert([
                        'organization_id' => $org->id, 'school_id' => $school, 'teacher_id' => $teacher,
                        'section_id' => $assignment->section_id, 'subject_id' => $assignment->subject_id,
                        'starts_on' => $data['effective_on'], 'ends_on' => $data['effective_on'],
                        'status' => 'ended', 'reason' => 'تكليف سابق غير مؤرخ؛ أُغلق عند النقل',
                        'recorded_by' => $request->attributes->get('jwt_user')?->id,
                        'created_at' => now(), 'updated_at' => now(),
                    ]);
                }
                DB::table('teacher_assignments')->where('id', $assignment->id)->delete();
            }

            $id = DB::table('jabalia_teacher_school_transfers')->insertGetId([
                'organization_id' => $org->id, 'teacher_id' => $teacher,
                'from_school_id' => $school, 'to_school_id' => $destination,
                'effective_on' => $data['effective_on'], 'reason' => $data['reason'] ?? null,
                'recorded_by' => $request->attributes->get('jwt_user')?->id,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['transfer_id' => $id, 'closed_assignments' => $assignments->count()], 201);
        });
    }

    private function tenant(Request $request, string $slug, int $school, int $teacher): ?object
    {
        $org = $request->attributes->get('organization');
        if (!$org || $slug !== 'jabalia' || $org->slug !== 'jabalia') return null;
        if (!DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists()) return null;
        if (!DB::table('organization_user')->where('organization_id', $org->id)
            ->where('user_id', $teacher)->where('role', 'teacher')->where('is_active', true)->exists()) return null;
        return $org;
    }
}
