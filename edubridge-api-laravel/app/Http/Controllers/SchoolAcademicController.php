<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SchoolAcademicController extends Controller
{
    private function school(Request $request): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) return null;

        if (($actor->role ?? null) === 'school') {
            $query = DB::table('school_accounts as a')
                ->join('schools as s', 's.id', '=', 'a.school_id')
                ->where('a.user_id', $actor->id);
        } else {
            $query = DB::table('school_management_assignments as a')
                ->join('schools as s', 's.id', '=', 'a.school_id')
                ->where('a.user_id', $actor->id)
                ->where('a.role', 'director')
                ->whereNull('a.ends_at');
        }
        $schools = $query->leftJoin('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('s.is_active', true)
            ->where(function ($q) {
                $q->whereNull('s.organization_id')->orWhere('o.is_active', true);
            })
            ->select('s.id', 's.name')->limit(2)->get();

        return $schools->count() === 1 ? $schools->first() : null;
    }

    public function index(Request $request): JsonResponse
    {
        $school = $this->school($request);
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);

        $years = DB::table('academic_years')->where('school_id', $school->id)
            ->select('id', 'school_id', 'name', 'starts_on', 'ends_on', 'is_current')
            ->orderByDesc('starts_on')->get();
        $grades = DB::table('grades')->where('school_id', $school->id)
            ->select('id', 'school_id', 'name')->orderBy('name')->get();
        $sections = DB::table('sections as s')
            ->join('grades as g', 'g.id', '=', 's.grade_id')
            ->join('academic_years as y', 'y.id', '=', 's.academic_year_id')
            ->where('g.school_id', $school->id)->where('y.school_id', $school->id)
            ->select('s.id', 'g.school_id', 's.name', 's.academic_year_id', 's.grade_id', 's.capacity')
            ->orderBy('s.name')->get();

        return response()->json([
            'school' => ['id' => (int) $school->id, 'name' => $school->name],
            'academic_years' => $years, 'grades' => $grades, 'sections' => $sections,
        ]);
    }

    private function input(Request $request, int $schoolId, array $rules): array|JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'expected_school_id' => ['required', 'integer', 'in:'.$schoolId],
            ...$rules,
        ]);
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }
        return $validator->validated();
    }

    public function storeYear(Request $request): JsonResponse
    {
        $school = $this->school($request);
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $this->input($request, (int) $school->id, [
            'name' => ['required', 'string', 'max:40'],
            'starts_on' => ['required', 'date_format:Y-m-d'],
            'ends_on' => ['required', 'date_format:Y-m-d', 'after:starts_on'],
            'is_current' => ['required', 'boolean'],
        ]);
        if ($data instanceof JsonResponse) return $data;

        return DB::transaction(function () use ($school, $data) {
            DB::table('schools')->where('id', $school->id)->lockForUpdate()->first();
            $name = trim($data['name']);
            if ($name === '' || DB::table('academic_years')->where('school_id', $school->id)->where('name', $name)->exists()) {
                return response()->json(['error' => 'Duplicate or empty year'], 409);
            }
            if ($data['is_current']) {
                DB::table('academic_years')->where('school_id', $school->id)
                    ->update(['is_current' => false, 'updated_at' => now()]);
            }
            $id = DB::table('academic_years')->insertGetId([
                'school_id' => $school->id, 'name' => $name,
                'starts_on' => $data['starts_on'], 'ends_on' => $data['ends_on'],
                'is_current' => $data['is_current'], 'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['school_id' => (int) $school->id,
                'item' => DB::table('academic_years')->find($id)], 201);
        });
    }

    public function storeGrade(Request $request): JsonResponse
    {
        $school = $this->school($request);
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $this->input($request, (int) $school->id, [
            'name' => ['required', 'string', 'max:80'],
        ]);
        if ($data instanceof JsonResponse) return $data;

        return DB::transaction(function () use ($school, $data) {
            DB::table('schools')->where('id', $school->id)->lockForUpdate()->first();
            $name = trim($data['name']);
            if ($name === '' || DB::table('grades')->where('school_id', $school->id)->where('name', $name)->exists()) {
                return response()->json(['error' => 'Duplicate or empty grade'], 409);
            }
            $id = DB::table('grades')->insertGetId([
                'school_id' => $school->id, 'name' => $name,
                'position' => 1, 'is_active' => true,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            return response()->json(['school_id' => (int) $school->id,
                'item' => DB::table('grades')->find($id)], 201);
        });
    }

    public function storeSection(Request $request): JsonResponse
    {
        $school = $this->school($request);
        if (!$school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $this->input($request, (int) $school->id, [
            'name' => ['required', 'string', 'max:80'],
            'academic_year_id' => ['required', 'integer', 'min:1'],
            'grade_id' => ['required', 'integer', 'min:1'],
            'capacity' => ['required', 'integer', 'between:1,500'],
        ]);
        if ($data instanceof JsonResponse) return $data;

        return DB::transaction(function () use ($school, $data) {
            DB::table('schools')->where('id', $school->id)->lockForUpdate()->first();
            $year = DB::table('academic_years')->where('id', $data['academic_year_id'])
                ->where('school_id', $school->id)->exists();
            $grade = DB::table('grades')->where('id', $data['grade_id'])
                ->where('school_id', $school->id)->exists();
            if (!$year || !$grade) return response()->json(['error' => 'Foreign year or grade'], 422);
            $name = trim($data['name']);
            if ($name === '' || DB::table('sections')->where('academic_year_id', $data['academic_year_id'])
                ->where('grade_id', $data['grade_id'])->where('name', $name)->exists()) {
                return response()->json(['error' => 'Duplicate or empty section'], 409);
            }
            $id = DB::table('sections')->insertGetId([
                'name' => $name, 'academic_year_id' => $data['academic_year_id'],
                'grade_id' => $data['grade_id'], 'capacity' => $data['capacity'],
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $item = DB::table('sections')->find($id);
            $item->school_id = (int) $school->id;
            return response()->json(['school_id' => (int) $school->id, 'item' => $item], 201);
        });
    }
}
