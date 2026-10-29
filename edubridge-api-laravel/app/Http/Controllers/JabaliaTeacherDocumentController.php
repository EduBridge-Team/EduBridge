<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaTeacherDocumentController extends Controller
{
    private function tenant(Request $request, string $slug, int $school, int $teacher): ?object
    {
        $org = $request->attributes->get('organization');
        if (!$org || $slug !== 'jabalia' || $org->slug !== 'jabalia') return null;
        if (!DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists()) return null;
        if (!DB::table('organization_user')->where('organization_id', $org->id)->where('user_id', $teacher)->where('role', 'teacher')->exists()) return null;
        return $org;
    }

    public function index(Request $request, string $organizationSlug, int $school, int $teacher): JsonResponse
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $rows = DB::table('jabalia_teacher_documents')
            ->where('organization_id', $org->id)->where('school_id', $school)->where('teacher_id', $teacher)
            ->orderByDesc('id')->paginate(30);
        return response()->json(['documents' => $rows]);
    }

    public function store(Request $request, string $organizationSlug, int $school, int $teacher): JsonResponse
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $data = $request->validate([
            'type' => ['required', 'in:contract,certificate'],
            'title' => ['required', 'string', 'max:200'],
            'issuer' => ['nullable', 'string', 'max:200'],
            'issued_on' => ['nullable', 'date_format:Y-m-d'],
            'expires_on' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:issued_on'],
            'notes' => ['nullable', 'string', 'max:5000'],
        ]);
        $id = DB::table('jabalia_teacher_documents')->insertGetId([
            'organization_id' => $org->id, 'school_id' => $school, 'teacher_id' => $teacher,
            ...$data, 'recorded_by' => $request->user()?->id,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        return response()->json(['document' => DB::table('jabalia_teacher_documents')->where('id', $id)->first()], 201);
    }

    public function destroy(Request $request, string $organizationSlug, int $school, int $teacher, int $document): JsonResponse
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $removed = DB::table('jabalia_teacher_documents')->where('id', $document)
            ->where('organization_id', $org->id)->where('school_id', $school)->where('teacher_id', $teacher)->delete();
        if (!$removed) return response()->json(['error' => 'السجل غير موجود'], 404);
        return response()->json(['removed' => true]);
    }
}
