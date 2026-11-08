<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaSuccessStoryController extends Controller
{
    private function school(Request $request, string $slug, int $school): ?object
    {
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        // Authorization is deliberately stricter than generic school access:
        // stories are private institutional drafts, not guardian publications.
        if ($slug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia'
            || ($actor->role ?? null) !== 'institution') return null;

        return DB::table('schools')
            ->where('id', $school)->where('organization_id', $org->id)->first();
    }

    private function belongsToSchool(int $org, int $school, int $child): bool
    {
        // Historical enrollment permits reporting progress after a transfer,
        // but never permits attaching a record for an unrelated student.
        return DB::table('student_enrollments as e')
            ->join('sections as s', 's.id', '=', 'e.section_id')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('children as c', 'c.id', '=', 'e.child_id')
            ->where('e.child_id', $child)->where('c.organization_id', $org)
            ->where('g.school_id', $school)->exists();
    }

    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->school($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $org = $request->attributes->get('organization');
        $stories = DB::table('jabalia_student_success_stories')
            ->where('organization_id', $org->id)->where('school_id', $school)
            ->orderByDesc('observed_on')->orderByDesc('id')
            ->select(['id', 'child_id', 'observed_on', 'title', 'narrative', 'created_at'])
            ->paginate(20);

        return response()->json([
            'stories' => $stories,
            'publication_status' => 'internal_only',
            'note' => 'سجل داخلي غير معتمد للنشر الخارجي؛ لا يحتوي مرفقات طبية',
        ]);
    }

    public function store(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->school($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }
        $data = $request->validate([
            'child_id' => ['required', 'integer', 'min:1'],
            'observed_on' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            'title' => ['required', 'string', 'min:3', 'max:160'],
            'narrative' => ['required', 'string', 'min:10', 'max:2000'],
        ]);
        $data['title'] = trim($data['title']);
        $data['narrative'] = trim($data['narrative']);
        if (mb_strlen($data['title']) < 3 || mb_strlen($data['narrative']) < 10) {
            return response()->json(['error' => 'عنوان القصة أو وصف التقدم غير مكتمل'], 422);
        }

        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');

        return DB::transaction(function () use ($org, $actor, $school, $data) {
            // Serialize with school-scoped mutations and revalidate membership
            // inside the transaction to avoid linking a different school's child.
            $current = DB::table('schools')->where('id', $school)
                ->where('organization_id', $org->id)->lockForUpdate()->first();
            if (!$current || !$this->belongsToSchool((int) $org->id, $school, (int) $data['child_id'])) {
                return response()->json(['error' => 'الطالب غير مسجل في تاريخ هذه المدرسة'], 404);
            }
            $id = DB::table('jabalia_student_success_stories')->insertGetId([
                'organization_id' => $org->id,
                'school_id' => $school,
                'child_id' => $data['child_id'],
                'observed_on' => $data['observed_on'],
                'title' => $data['title'],
                'narrative' => $data['narrative'],
                'recorded_by' => $actor->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            return response()->json([
                'story' => DB::table('jabalia_student_success_stories')
                    ->where('id', $id)
                    ->first(['id', 'child_id', 'observed_on', 'title', 'narrative', 'created_at']),
                'publication_status' => 'internal_only',
            ], 201);
        });
    }
}
