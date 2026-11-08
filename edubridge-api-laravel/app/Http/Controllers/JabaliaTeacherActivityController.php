<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class JabaliaTeacherActivityController extends Controller
{
    private const TYPES = ['classroom_activity', 'teacher_training', 'school_activity', 'other'];

    private function authorizedSchool(Request $request, string $slug, int $school): ?object
    {
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if ($slug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia'
            || ($actor->role ?? null) !== 'institution') return null;

        return DB::table('schools')->where('id', $school)
            ->where('organization_id', $org->id)->where('is_active', true)->first();
    }

    private function assignedTeachers(int $organization, int $school)
    {
        return DB::table('users as u')
            ->join('organization_user as ou', 'ou.user_id', '=', 'u.id')
            ->join('teacher_assignments as a', 'a.teacher_id', '=', 'u.id')
            ->join('sections as s', 's.id', '=', 'a.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->where('ou.organization_id', $organization)
            ->where('ou.role', 'teacher')->where('ou.is_active', true)
            ->where('u.role', 'teacher')->where('g.school_id', $school)->where('a.status', 'active')
            ->distinct();
    }

    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->authorizedSchool($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $org = $request->attributes->get('organization');
        $teachers = $this->assignedTeachers((int) $org->id, $school)
            ->orderBy('u.name')->get(['u.id', 'u.name']);
        $items = DB::table('jabalia_teacher_activities as a')
            ->join('users as u', 'u.id', '=', 'a.teacher_id')
            ->where('a.organization_id', $org->id)->where('a.school_id', $school)
            ->orderByDesc('a.activity_on')->orderByDesc('a.id')
            ->select(['a.id','a.teacher_id','u.name as teacher_name','a.activity_on',
                'a.activity_type','a.title','a.summary','a.created_at'])
            ->paginate(20);

        return response()->json([
            'teachers' => $teachers,
            'activities' => $items,
            'privacy' => 'institution_only',
            'note' => 'سجل أنشطة داخلي ولا يثبت الامتثال الوظيفي أو وجود عقود عمل موقعة',
        ]);
    }

    public function store(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->authorizedSchool($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $data = $request->validate([
            'teacher_id' => ['required', 'integer', 'min:1'],
            'activity_on' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            'activity_type' => ['required', Rule::in(self::TYPES)],
            'title' => ['required', 'string', 'min:3', 'max:160'],
            'summary' => ['required', 'string', 'min:10', 'max:2000'],
        ]);
        $data['title'] = trim($data['title']);
        $data['summary'] = trim($data['summary']);
        if (mb_strlen($data['title']) < 3 || mb_strlen($data['summary']) < 10) {
            return response()->json(['error' => 'عنوان النشاط أو الملخص غير مكتمل'], 422);
        }

        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');

        return DB::transaction(function () use ($data, $org, $actor, $school) {
            $current = DB::table('schools')
                ->where('id', $school)->where('organization_id', $org->id)
                ->where('is_active', true)->lockForUpdate()->first();
            if (!$current) return response()->json(['error' => 'المدرسة غير موجودة'], 404);
            $membership = DB::table('organization_user')
                ->where('organization_id', $org->id)->where('user_id', $data['teacher_id'])
                ->where('role', 'teacher')->where('is_active', true)
                ->lockForUpdate()->first();
            if (!$membership || !$this->assignedTeachers((int) $org->id, $school)
                ->where('u.id', $data['teacher_id'])->exists()) {
                return response()->json(['error' => 'المعلم غير مكلف حاليًا في هذه المدرسة'], 404);
            }

            $id = DB::table('jabalia_teacher_activities')->insertGetId([
                'organization_id' => $org->id,
                'school_id' => $school,
                'teacher_id' => $data['teacher_id'],
                'activity_on' => $data['activity_on'],
                'activity_type' => $data['activity_type'],
                'title' => $data['title'],
                'summary' => $data['summary'],
                'recorded_by' => $actor->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            return response()->json([
                'activity' => DB::table('jabalia_teacher_activities')
                    ->where('id', $id)->first([
                        'id','teacher_id','activity_on','activity_type','title','summary','created_at',
                    ]),
                'privacy' => 'institution_only',
            ], 201);
        });
    }
}
