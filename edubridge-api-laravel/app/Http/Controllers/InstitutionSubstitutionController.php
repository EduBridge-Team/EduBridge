<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InstitutionSubstitutionController extends Controller
{
    public function reportAbsence(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'teacher_id' => ['required', 'integer', 'exists:users,id'],
            'absence_date' => ['required', 'date'],
            'reason' => ['nullable', 'string', 'max:2000'],
        ]);

        if (!$this->teacherWithinOrganization($request, (int) $data['teacher_id'])) {
            return response()->json(['error' => 'المعلم لا يتبع هذه المؤسسة'], 422);
        }

        $actor = $request->attributes->get('jwt_user');
        $id = DB::table('teacher_absences')->updateOrInsert(
            ['school_id' => $school, 'teacher_id' => $data['teacher_id'], 'absence_date' => $data['absence_date']],
            ['reason' => $data['reason'] ?? null, 'status' => 'confirmed', 'reported_by' => $actor->id ?? null, 'updated_at' => now(), 'created_at' => now()]
        );

        $absence = DB::table('teacher_absences')
            ->where('school_id', $school)
            ->where('teacher_id', $data['teacher_id'])
            ->where('absence_date', $data['absence_date'])
            ->first();

        $weekday = ((int) date('w', strtotime($data['absence_date']))) + 1;
        $affected = DB::table('timetable_entries as t')
            ->join('sections as s', 's.id', '=', 't.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('subjects as sub', 'sub.id', '=', 't.subject_id')
            ->where('t.school_id', $school)
            ->where('t.teacher_id', $data['teacher_id'])
            ->where('t.weekday', $weekday)
            ->select('t.*', 's.name as section_name', 'g.name as grade_name', 'sub.name as subject_name')
            ->orderBy('t.period_number')
            ->get();

        return response()->json(['absence' => $absence, 'affected_classes' => $affected], 201);
    }

    public function availableTeachers(Request $request, string $organizationSlug, int $school, int $entry): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $date = $request->query('date');
        if (!$date || !strtotime($date)) {
            return response()->json(['error' => 'التاريخ مطلوب'], 422);
        }

        $slot = DB::table('timetable_entries')->where('id', $entry)->where('school_id', $school)->first();
        if (!$slot) {
            return response()->json(['error' => 'الحصة غير موجودة'], 404);
        }

        $organization = $request->attributes->get('organization');
        $busyIds = DB::table('timetable_entries')
            ->where('school_id', $school)
            ->where('weekday', $slot->weekday)
            ->where('period_number', $slot->period_number)
            ->whereNotNull('teacher_id')
            ->pluck('teacher_id');

        $absentIds = DB::table('teacher_absences')
            ->where('school_id', $school)
            ->whereDate('absence_date', $date)
            ->where('status', 'confirmed')
            ->pluck('teacher_id');

        $substituteIds = DB::table('class_substitutions as cs')
            ->join('timetable_entries as t', 't.id', '=', 'cs.timetable_entry_id')
            ->where('t.school_id', $school)
            ->where('t.weekday', $slot->weekday)
            ->where('t.period_number', $slot->period_number)
            ->whereDate('cs.class_date', $date)
            ->where('cs.status', 'assigned')
            ->pluck('cs.substitute_teacher_id');

        $excluded = $busyIds->merge($absentIds)->merge($substituteIds)->push($slot->teacher_id)->filter()->unique()->values();

        $teachers = DB::table('organization_user as ou')
            ->join('users as u', 'u.id', '=', 'ou.user_id')
            ->where('ou.organization_id', $organization->id)
            ->where('ou.is_active', true)
            ->where('ou.role', 'teacher')
            ->when($excluded->isNotEmpty(), fn ($q) => $q->whereNotIn('u.id', $excluded->all()))
            ->select('u.id', 'u.name')
            ->orderBy('u.name')
            ->get();

        return response()->json(['available_teachers' => $teachers]);
    }

    public function assign(Request $request, string $organizationSlug, int $school, int $entry): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $slot = DB::table('timetable_entries')->where('id', $entry)->where('school_id', $school)->first();
        if (!$slot) {
            return response()->json(['error' => 'الحصة غير موجودة'], 404);
        }

        $data = $request->validate([
            'class_date' => ['required', 'date'],
            'substitute_teacher_id' => ['required', 'integer', 'exists:users,id'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if (!$this->teacherWithinOrganization($request, (int) $data['substitute_teacher_id'])) {
            return response()->json(['error' => 'المعلم البديل لا يتبع هذه المؤسسة'], 422);
        }

        $weekday = ((int) date('w', strtotime($data['class_date']))) + 1;
        if ($weekday !== (int) $slot->weekday) {
            return response()->json(['error' => 'تاريخ البديل لا يطابق يوم الحصة في الجدول'], 422);
        }

        $busy = DB::table('timetable_entries')
            ->where('school_id', $school)
            ->where('teacher_id', $data['substitute_teacher_id'])
            ->where('weekday', $slot->weekday)
            ->where('period_number', $slot->period_number)
            ->exists();

        $absent = DB::table('teacher_absences')
            ->where('school_id', $school)
            ->where('teacher_id', $data['substitute_teacher_id'])
            ->whereDate('absence_date', $data['class_date'])
            ->where('status', 'confirmed')
            ->exists();

        $assignedElsewhere = DB::table('class_substitutions as cs')
            ->join('timetable_entries as t', 't.id', '=', 'cs.timetable_entry_id')
            ->where('t.school_id', $school)
            ->where('t.weekday', $slot->weekday)
            ->where('t.period_number', $slot->period_number)
            ->whereDate('cs.class_date', $data['class_date'])
            ->where('cs.substitute_teacher_id', $data['substitute_teacher_id'])
            ->where('cs.status', 'assigned')
            ->where('cs.timetable_entry_id', '!=', $entry)
            ->exists();

        if ($busy || $absent || $assignedElsewhere || (int) $slot->teacher_id === (int) $data['substitute_teacher_id']) {
            return response()->json(['error' => 'المعلم البديل غير متاح في هذه الحصة'], 409);
        }

        $actor = $request->attributes->get('jwt_user');
        DB::table('class_substitutions')->updateOrInsert(
            ['timetable_entry_id' => $entry, 'class_date' => $data['class_date']],
            [
                'original_teacher_id' => $slot->teacher_id,
                'substitute_teacher_id' => $data['substitute_teacher_id'],
                'status' => 'assigned',
                'notes' => $data['notes'] ?? null,
                'assigned_by' => $actor->id ?? null,
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );

        return response()->json([
            'substitution' => DB::table('class_substitutions')->where('timetable_entry_id', $entry)->where('class_date', $data['class_date'])->first(),
        ], 201);
    }

    private function schoolWithinTenant(Request $request, int $school): ?object
    {
        $organization = $request->attributes->get('organization');
        return DB::table('schools')->where('id', $school)->where('organization_id', $organization->id)->first();
    }

    private function teacherWithinOrganization(Request $request, int $teacher): bool
    {
        $organization = $request->attributes->get('organization');
        return DB::table('organization_user')
            ->where('organization_id', $organization->id)
            ->where('user_id', $teacher)
            ->where('is_active', true)
            ->where('role', 'teacher')
            ->exists();
    }
}
