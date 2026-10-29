<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

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

    public function upload(Request $request, string $organizationSlug, int $school, int $teacher, int $document): JsonResponse
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $row = DB::table('jabalia_teacher_documents')->where('id', $document)
            ->where('organization_id', $org->id)->where('school_id', $school)->where('teacher_id', $teacher)->first();
        if (!$row) return response()->json(['error' => 'السجل غير موجود'], 404);
        $validated = $request->validate([
            'file' => ['required', 'file', 'max:5120', 'mimetypes:application/pdf,image/jpeg,image/png,image/webp'],
        ]);
        $file = $validated['file'];
        $ext = match ($file->getMimeType()) {
            'application/pdf' => 'pdf', 'image/jpeg' => 'jpg',
            'image/png' => 'png', 'image/webp' => 'webp',
            default => null,
        };
        if (!$ext) return response()->json(['error' => 'نوع الملف غير مدعوم'], 422);
        $path = Storage::disk('local')->putFileAs('jabalia-teacher-documents', $file, Str::uuid().'.'.$ext);
        if (!$path) return response()->json(['error' => 'تعذر حفظ الملف'], 500);
        try {
            $previousPath = DB::transaction(function () use ($org, $school, $teacher, $document, $path, $file) {
                $current = DB::table('jabalia_teacher_documents')->where('id', $document)
                    ->where('organization_id', $org->id)->where('school_id', $school)
                    ->where('teacher_id', $teacher)->lockForUpdate()->first();
                if (!$current) return false;
                DB::table('jabalia_teacher_documents')->where('id', $document)
                    ->where('organization_id', $org->id)->where('school_id', $school)
                    ->where('teacher_id', $teacher)->update([
                        'storage_path' => $path,
                        'original_filename' => mb_substr(basename($file->getClientOriginalName()), 0, 255),
                        'mime_type' => $file->getMimeType(),
                        'file_size' => $file->getSize(),
                        'updated_at' => now(),
                    ]);
                return $current->storage_path;
            });
        } catch (\Throwable $error) {
            Storage::disk('local')->delete($path);
            throw $error;
        }
        if ($previousPath === false) {
            Storage::disk('local')->delete($path);
            return response()->json(['error' => 'السجل غير موجود'], 404);
        }
        if ($previousPath && $previousPath !== $path) Storage::disk('local')->delete($previousPath);
        return response()->json(['uploaded' => true]);
    }

    public function download(Request $request, string $organizationSlug, int $school, int $teacher, int $document)
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $row = DB::table('jabalia_teacher_documents')->where('id', $document)
            ->where('organization_id', $org->id)->where('school_id', $school)->where('teacher_id', $teacher)->first();
        if (!$row || !$row->storage_path || !Storage::disk('local')->exists($row->storage_path)) {
            return response()->json(['error' => 'الملف غير موجود'], 404);
        }
        return Storage::disk('local')->download($row->storage_path, $row->original_filename ?: 'document', [
            'Cache-Control' => 'private, no-store',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function destroy(Request $request, string $organizationSlug, int $school, int $teacher, int $document): JsonResponse
    {
        $org = $this->tenant($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'المعلم أو المدرسة غير موجود'], 404);
        $previousPath = DB::transaction(function () use ($org, $school, $teacher, $document) {
            $row = DB::table('jabalia_teacher_documents')->where('id', $document)
                ->where('organization_id', $org->id)->where('school_id', $school)
                ->where('teacher_id', $teacher)->lockForUpdate()->first();
            if (!$row) return false;
            DB::table('jabalia_teacher_documents')->where('id', $document)
                ->where('organization_id', $org->id)->where('school_id', $school)
                ->where('teacher_id', $teacher)->delete();
            return $row->storage_path;
        });
        if ($previousPath === false) return response()->json(['error' => 'السجل غير موجود'], 404);
        if ($previousPath) Storage::disk('local')->delete($previousPath);
        return response()->json(['removed' => true]);
    }
}
