<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class JabaliaAdmissionReadinessController extends Controller
{
    private const REQUIRED_TYPES = [
        'audiology_report', 'birth_certificate', 'medical_report',
        'child_photo', 'father_identity',
    ];

    /**
     * Management-facing preparation only. Metadata presence is NOT a clinical
     * review, counselor clearance, or an enrollment authorization.
     */
    public function index(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        // School mailboxes, staff, parents and specialists cannot browse the
        // pending applicant inventory via this management-only endpoint.
        if (!$actor || ($actor->role ?? null) === 'school') {
            return response()->json(['error' => 'Not found'], 404);
        }
        $school = SchoolScopedAccess::resolve($request, 'enrollment');
        if (!$school || !in_array($school->management_role ?? null, ['director', 'deputy_director'], true)) {
            return response()->json(['error' => 'Not found'], 404);
        }
        $jabalia = DB::table('schools as s')
            ->join('organizations as o', 'o.id', '=', 's.organization_id')
            ->where('s.id', $school->id)
            ->where('s.is_active', true)->where('o.is_active', true)
            ->where('o.slug', 'jabalia')->exists();
        if (!$jabalia) {
            return response()->json(['error' => 'Not found'], 404);
        }
        if (!Schema::hasTable('jabalia_admission_documents')) {
            return response()->json(['error' => 'Admission evidence metadata unavailable'], 503);
        }

        $requests = DB::table('school_enrollment_requests')
            ->where('school_id', $school->id)->where('status', 'pending')
            ->orderBy('created_at')->orderBy('id')
            ->limit(200)
            ->get(['id', 'child_id', 'version', 'created_at']);
        $ids = $requests->pluck('id')->all();

        // Both the request and child linkage must match; never use a global
        // document count or leak another school's records.
        $types = DB::table('jabalia_admission_documents as d')
            ->join('school_enrollment_requests as r', function ($join) {
                $join->on('r.id', '=', 'd.enrollment_request_id')
                    ->on('r.child_id', '=', 'd.child_id')
                    ->on('r.school_id', '=', 'd.school_id');
            })
            ->where('d.school_id', $school->id)
            ->whereIn('d.enrollment_request_id', $ids)
            ->distinct()
            ->get(['d.enrollment_request_id', 'd.type'])
            ->groupBy('enrollment_request_id');

        $rows = $requests->map(function ($entry) use ($types) {
            $present = collect($types->get($entry->id, []))
                ->pluck('type')->filter(fn ($value) => in_array($value, self::REQUIRED_TYPES, true))
                ->unique()->values()->all();
            $missing = array_values(array_diff(self::REQUIRED_TYPES, $present));
            return [
                'request_id' => (int) $entry->id,
                'child_id' => (int) $entry->child_id,
                'version' => (int) $entry->version,
                'recorded_types' => $present,
                'missing_types' => $missing,
                'evidence_categories_recorded' => count($missing) === 0,
                'counselor_review_completed' => false,
                'administration_approved' => false,
                'approval_allowed' => false,
            ];
        });

        return response()->json([
            'school_id' => (int) $school->id,
            'items' => $rows,
            'required_types' => self::REQUIRED_TYPES,
            'upload_enabled' => config('services.jabalia_admissions.upload_enabled') === true,
            'approval_allowed' => false,
            'note' => 'The document categories are unverified metadata. No counselor assessment or administrative admission approval has occurred.',
        ]);
    }
}
