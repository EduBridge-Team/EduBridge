<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Confidential Jabalia-only enrollment evidence intake, NOT an admissions decision.
 *
 * The existing enrollment approval must not be described as Jabalia-approved until
 * the counselor review/administration sign-off flow is separately implemented.
 */
class JabaliaAdmissionEvidenceController extends Controller
{
    private const TYPES = [
        'audiology_report', 'birth_certificate', 'medical_report',
        'child_photo', 'father_identity',
    ];

    private function parentRequest(Request $request, int $child, int $enrollmentRequest, bool $pending = false): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || ($actor->role ?? null) !== 'parent') return null;
        if (!DB::table('child_parent')->where('child_id', $child)
            ->where('parent_id', $actor->id)->exists()) return null;

        return DB::table('school_enrollment_requests as r')
            ->join('schools as s', 's.id', '=', 'r.school_id')
            ->join('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('r.id', $enrollmentRequest)->where('r.child_id', $child)
            ->where('o.slug', 'jabalia')->where('o.is_active', true)
            ->where('s.is_active', true)
            ->when($pending, fn ($query) => $query->where('r.status', 'pending'))
            ->select('r.id', 'r.child_id', 'r.school_id', 'r.status')->first();
    }

    private function schoolRequest(Request $request, int $enrollmentRequest): ?object
    {
        $actor = $request->attributes->get('jwt_user');
        // Sensitive audiology/identity files are NOT visible to the official school
        // mailbox, teachers, or specialists. The institution counselor role has not
        // yet been approved and therefore receives no access in this first batch.
        if (!$actor || ($actor->role ?? null) === 'school') return null;
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school || !in_array($school->management_role ?? null, ['director', 'deputy_director'], true)) {
            return null;
        }
        return DB::table('school_enrollment_requests as r')
            ->join('schools as s', 's.id', '=', 'r.school_id')
            ->join('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('r.id', $enrollmentRequest)->where('r.school_id', $school->id)
            ->where('o.slug', 'jabalia')->where('o.is_active', true)
            ->select('r.id', 'r.child_id', 'r.school_id', 'r.status')->first();
    }

    private function audit(Request $request, object $enrollment, ?int $document, string $action): void
    {
        // Fail closed: evidence access must not silently bypass audit persistence.
        DB::table('jabalia_admission_evidence_access_events')->insert([
            'school_id' => $enrollment->school_id,
            'child_id' => $enrollment->child_id,
            'enrollment_request_id' => $enrollment->id,
            'document_id' => $document,
            'action' => $action,
            'actor_id' => $request->attributes->get('jwt_user')->id,
            'actor_role' => $request->attributes->get('jwt_user')->role,
            'created_at' => now(),
        ]);
    }

    private function auditReady(): bool
    {
        return Schema::hasTable('jabalia_admission_evidence_access_events');
    }

    public function schoolAccessEvents(Request $request, int $enrollmentRequest): JsonResponse
    {
        $enrollment = $this->schoolRequest($request, $enrollmentRequest);
        if (!$enrollment) return response()->json(['error' => 'Not found'], 404);
        if (!$this->auditReady()) return response()->json(['error' => 'Access audit unavailable'], 503);
        $this->audit($request, $enrollment, null, 'audit_viewed');
        $events = DB::table('jabalia_admission_evidence_access_events')
            ->where('school_id', $enrollment->school_id)
            ->where('child_id', $enrollment->child_id)
            ->where('enrollment_request_id', $enrollment->id)
            ->orderByDesc('id')->select([
                'id', 'document_id', 'action', 'actor_id', 'actor_role', 'created_at',
            ])->paginate(30);
        return response()->json(['events' => $events]);
    }

    private function metadata(object $record): array
    {
        return [
            'id' => (int) $record->id,
            'type' => $record->type,
            'file_size' => (int) $record->file_size,
            'created_at' => $record->created_at,
        ];
    }

    private function listFor(Request $request, object $enrollment): JsonResponse
    {
        $rows = DB::table('jabalia_admission_documents')
            ->where('enrollment_request_id', $enrollment->id)
            ->where('child_id', $enrollment->child_id)
            ->where('school_id', $enrollment->school_id)
            ->orderBy('id')->get();
        $this->audit($request, $enrollment, null, 'listed');
        return response()->json([
            'request_id' => (int) $enrollment->id,
            'documents' => $rows->map(fn ($row) => $this->metadata($row))->all(),
            'required_types' => self::TYPES,
            'evidence_complete' => count(array_unique($rows->pluck('type')->all())) >= count(self::TYPES)
                && count(array_diff(self::TYPES, $rows->pluck('type')->all())) === 0,
            'admissions_approved' => false,
            // The server-side operational gate remains disabled by default.
            'uploads_enabled' => config('services.jabalia_admissions.upload_enabled') === true,
            'note' => 'Evidence completeness is not a counselor or school admission approval.',
        ]);
    }

    public function parentIndex(Request $request, int $child, int $enrollmentRequest): JsonResponse
    {
        $enrollment = $this->parentRequest($request, $child, $enrollmentRequest);
        if (!$enrollment) return response()->json(['error' => 'Not found'], 404);
        if (!$this->auditReady()) return response()->json(['error' => 'Access audit unavailable'], 503);
        return $this->listFor($request, $enrollment);
    }

    public function schoolIndex(Request $request, int $enrollmentRequest): JsonResponse
    {
        $enrollment = $this->schoolRequest($request, $enrollmentRequest);
        if (!$enrollment) return response()->json(['error' => 'Not found'], 404);
        if (!$this->auditReady()) return response()->json(['error' => 'Access audit unavailable'], 503);
        return $this->listFor($request, $enrollment);
    }

    public function store(Request $request, int $child, int $enrollmentRequest): JsonResponse
    {
        // This is intentionally disabled in every deployment by default.
        // An administrator must verify volume persistence, encrypted backup and
        // authorized processing before any medical/identity file is accepted.
        if (config('services.jabalia_admissions.upload_enabled') !== true) {
            return response()->json(['error' => 'Jabalia admission uploads are not activated'], 503);
        }
        $enrollment = $this->parentRequest($request, $child, $enrollmentRequest, true);
        if (!$enrollment) return response()->json(['error' => 'Pending request not found'], 404);

        $data = $request->validate([
            'type' => ['required', 'in:'.implode(',', self::TYPES)],
            'file' => ['required', 'file', 'max:5120',
                'mimetypes:application/pdf,image/jpeg,image/png,image/webp'],
        ]);
        $file = $data['file'];
        $extension = match ($file->getMimeType()) {
            'application/pdf' => 'pdf',
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => null,
        };
        if (!$extension) return response()->json(['error' => 'Invalid file format'], 422);
        $path = Storage::disk('local')->putFileAs(
            'jabalia-admission-documents', $file, Str::uuid().'.'.$extension
        );
        if (!$path) return response()->json(['error' => 'Unable to save document'], 500);

        try {
            $result = DB::transaction(function () use ($request, $enrollment, $path, $file, $data) {
                // Recheck after acquiring the same request row lock used by admission decisions.
                $current = DB::table('school_enrollment_requests')
                    ->where('id', $enrollment->id)
                    ->where('child_id', $enrollment->child_id)
                    ->where('school_id', $enrollment->school_id)
                    ->lockForUpdate()->first();
                if (!$current || $current->status !== 'pending') return null;
                $id = DB::table('jabalia_admission_documents')->insertGetId([
                    'enrollment_request_id' => $current->id,
                    'school_id' => $current->school_id,
                    'child_id' => $current->child_id,
                    'type' => $data['type'],
                    'storage_path' => $path,
                    'mime_type' => $file->getMimeType(),
                    'file_size' => $file->getSize(),
                    'uploaded_by' => $request->attributes->get('jwt_user')->id,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                $this->audit($request, $enrollment, $id, 'uploaded');
                return DB::table('jabalia_admission_documents')->where('id', $id)->first();
            });
        } catch (\Throwable $error) {
            Storage::disk('local')->delete($path);
            throw $error;
        }
        if (!$result) {
            Storage::disk('local')->delete($path);
            return response()->json(['error' => 'Request state changed'], 409);
        }
        return response()->json(['document' => $this->metadata($result)], 201);
    }

    private function downloadFor(Request $request, object $enrollment, int $document)
    {
        $row = DB::table('jabalia_admission_documents')
            ->where('id', $document)
            ->where('enrollment_request_id', $enrollment->id)
            ->where('school_id', $enrollment->school_id)
            ->where('child_id', $enrollment->child_id)->first();
        if (!$row || !Storage::disk('local')->exists($row->storage_path)) {
            return response()->json(['error' => 'Not found'], 404);
        }
        // Do not expose original filenames or predictable storage paths to browsers.
        $extension = match ($row->mime_type) {
            'application/pdf' => 'pdf', 'image/jpeg' => 'jpg',
            'image/png' => 'png', 'image/webp' => 'webp',
            default => null,
        };
        if (!$extension) return response()->json(['error' => 'Unavailable'], 404);
        if (!$this->auditReady()) return response()->json(['error' => 'Access audit unavailable'], 503);
        // The event proves issuance of a response, not successful network delivery.
        $this->audit($request, $enrollment, $document, 'download_issued');
        return Storage::disk('local')->download(
            $row->storage_path, 'admission-document-'.$row->id.'.'.$extension,
            ['Cache-Control' => 'private, no-store', 'X-Content-Type-Options' => 'nosniff']
        );
    }

    public function parentDownload(Request $request, int $child, int $enrollmentRequest, int $document)
    {
        $enrollment = $this->parentRequest($request, $child, $enrollmentRequest);
        if (!$enrollment) return response()->json(['error' => 'Not found'], 404);
        return $this->downloadFor($request, $enrollment, $document);
    }

    public function schoolDownload(Request $request, int $enrollmentRequest, int $document)
    {
        $enrollment = $this->schoolRequest($request, $enrollmentRequest);
        if (!$enrollment) return response()->json(['error' => 'Not found'], 404);
        return $this->downloadFor($request, $enrollment, $document);
    }
}
