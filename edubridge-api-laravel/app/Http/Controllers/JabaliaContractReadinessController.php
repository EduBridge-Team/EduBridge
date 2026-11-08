<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaContractReadinessController extends Controller
{
    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        // Aggregate-only, confidential institution administration report.
        if ($organizationSlug !== 'jabalia' || ($org->slug ?? null) !== 'jabalia'
            || ($actor->role ?? null) !== 'institution'
            || !DB::table('schools')->where('id', $school)
                ->where('organization_id', $org->id)->exists()) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $records = DB::table('jabalia_teacher_documents')
            ->where('organization_id', $org->id)->where('school_id', $school)
            ->where('type', 'contract');

        $total = (clone $records)->count();
        $withPath = (clone $records)->whereNotNull('storage_path')->count();
        $expired = (clone $records)->whereNotNull('expires_on')
            ->whereDate('expires_on', '<', now()->toDateString())->count();
        $noExpiry = (clone $records)->whereNull('expires_on')->count();
        $teachers = (clone $records)->distinct()->count('teacher_id');

        $periodsAvailable = \Illuminate\Support\Facades\Schema::hasTable('jabalia_teacher_contract_periods');
        $periodStats = [
            'periods_recorded' => null,
            'periods_current_by_date' => null,
            'periods_ended_by_date' => null,
            'periods_upcoming_by_date' => null,
            'periods_ending_within_30_days' => null,
            'renewals_recorded' => null,
        ];
        if ($periodsAvailable) {
            $periods = DB::table('jabalia_teacher_contract_periods')
                ->where('organization_id', $org->id)->where('school_id', $school);
            $today = now('Asia/Hebron')->toDateString();
            $threshold = now('Asia/Hebron')->addDays(30)->toDateString();
            $periodStats = [
                'periods_recorded' => (clone $periods)->count(),
                'periods_current_by_date' => (clone $periods)->whereDate('starts_on', '<=', $today)
                    ->whereDate('ends_on', '>=', $today)->count(),
                'periods_ended_by_date' => (clone $periods)->whereDate('ends_on', '<', $today)->count(),
                'periods_upcoming_by_date' => (clone $periods)->whereDate('starts_on', '>', $today)->count(),
                'periods_ending_within_30_days' => (clone $periods)
                    ->whereDate('starts_on', '<=', $today)
                    ->whereDate('ends_on', '>=', $today)
                    ->whereDate('ends_on', '<=', $threshold)->count(),
                'renewals_recorded' => (clone $periods)->whereNotNull('previous_period_id')->count(),
            ];
        }

        return response()->json([
            'school_id' => $school,
            'contract_records' => $total,
            'records_with_attached_path' => $withPath,
            'metadata_only_records' => $total - $withPath,
            'records_expired_by_date' => $expired,
            'records_without_expiry_date' => $noExpiry,
            'teachers_with_contract_records' => $teachers,
            'contract_periods_available' => $periodsAvailable,
            ...$periodStats,
            'attachment_integrity_verified' => false,
            'note' => 'ملخص للسجلات فقط؛ مسار الملف لا يثبت وجود النسخة الموقعة أو صحتها القانونية',
        ]);
    }
}
