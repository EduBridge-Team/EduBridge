<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

class JabaliaTeacherContractPeriodController extends Controller
{
    private function scope(Request $request, string $slug, int $school, int $teacher): ?object
    {
        $organization = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if (!$organization || ($organization->slug ?? null) !== 'jabalia'
            || $slug !== 'jabalia' || ($actor->role ?? null) !== 'institution') {
            return null;
        }
        if (!DB::table('schools')->where('id', $school)
            ->where('organization_id', $organization->id)
            ->where('is_active', true)->exists()) return null;
        if (!DB::table('organization_user')->where('organization_id', $organization->id)
            ->where('user_id', $teacher)->where('role', 'teacher')
            ->where('is_active', true)->exists()) return null;

        return $organization;
    }

    private function audit(Request $request, object $org, int $school, int $teacher,
        ?int $document, string $action): void
    {
        DB::table('jabalia_teacher_document_access_events')->insert([
            'organization_id' => $org->id,
            'school_id' => $school,
            'teacher_id' => $teacher,
            'document_id' => $document,
            'action' => $action,
            'actor_id' => $request->attributes->get('jwt_user')->id,
            'created_at' => now(),
        ]);
    }

    private function missingSchema(): bool
    {
        return !Schema::hasTable('jabalia_teacher_contract_periods')
            || !Schema::hasTable('jabalia_teacher_document_access_events');
    }

    public function index(Request $request, string $organizationSlug, int $school, int $teacher): JsonResponse
    {
        $org = $this->scope($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'Not found'], 404);
        if ($this->missingSchema()) return response()->json(['error' => 'Contract records unavailable'], 503);

        $rows = DB::table('jabalia_teacher_contract_periods')
            ->where('organization_id', $org->id)
            ->where('school_id', $school)->where('teacher_id', $teacher)
            ->orderByDesc('starts_on')->orderByDesc('id')
            ->select(['id','contract_document_id','previous_period_id','project_name',
                'starts_on','ends_on','signed_on','recorded_by','created_at'])
            ->paginate(20);

        $today = now('Asia/Hebron')->toDateString();
        $rows->setCollection($rows->getCollection()->map(function (object $period) use ($today) {
            $state = $period->ends_on < $today ? 'ended'
                : ($period->starts_on > $today ? 'upcoming' : 'within_recorded_dates');
            return [
                'id' => (int) $period->id,
                'contract_document_id' => (int) $period->contract_document_id,
                'previous_period_id' => $period->previous_period_id !== null
                    ? (int) $period->previous_period_id : null,
                'project_name' => $period->project_name,
                'starts_on' => $period->starts_on,
                'ends_on' => $period->ends_on,
                'signed_on' => $period->signed_on,
                'recorded_by' => $period->recorded_by,
                'created_at' => $period->created_at,
                'date_state' => $state,
            ];
        }));

        // A listing is an access to confidential employment metadata too.
        // Fail closed if the append-only access event cannot be recorded.
        $this->audit($request, $org, $school, $teacher, null, 'contract_periods_listed');

        return response()->json([
            'school_id' => $school,
            'teacher_id' => $teacher,
            'periods' => $rows,
            'immutable' => true,
            'attachment_integrity_verified' => false,
            'employment_legally_verified' => false,
            'note' => 'التواريخ المسجلة ليست إثباتًا قانونيًا لتوقيع أو سريان عقد العمل',
        ]);
    }

    public function store(Request $request, string $organizationSlug, int $school, int $teacher): JsonResponse
    {
        $org = $this->scope($request, $organizationSlug, $school, $teacher);
        if (!$org) return response()->json(['error' => 'Not found'], 404);
        if ($this->missingSchema()) return response()->json(['error' => 'Contract records unavailable'], 503);

        $data = $request->validate([
            'contract_document_id' => ['required', 'integer', 'min:1'],
            'previous_period_id' => ['nullable', 'integer', 'min:1'],
            'project_name' => ['required', 'string', 'min:2', 'max:160'],
            'starts_on' => ['required', 'date_format:Y-m-d'],
            'ends_on' => ['required', 'date_format:Y-m-d', 'after_or_equal:starts_on'],
            'signed_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
        ]);
        $data['project_name'] = trim($data['project_name']);
        if (mb_strlen($data['project_name']) < 2) {
            return response()->json(['error' => 'اسم المشروع غير مكتمل'], 422);
        }

        return DB::transaction(function () use ($request, $org, $school, $teacher, $data) {
            $locked = DB::table('schools')->where('id', $school)
                ->where('organization_id', $org->id)
                ->where('is_active', true)->lockForUpdate()->first();
            if (!$locked || !$this->scope($request, 'jabalia', $school, $teacher)) {
                return response()->json(['error' => 'Not found'], 404);
            }

            $doc = DB::table('jabalia_teacher_documents')
                ->where('id', $data['contract_document_id'])
                ->where('organization_id', $org->id)
                ->where('school_id', $school)->where('teacher_id', $teacher)
                ->where('type', 'contract')->lockForUpdate()->first();

            if (!$doc || !$doc->storage_path) {
                return response()->json(['error' => 'يجب إرفاق نسخة العقد الخاصة قبل تسجيل مدة العقد'], 422);
            }
            if (!Storage::disk('local')->exists($doc->storage_path)) {
                return response()->json(['error' => 'ملف العقد غير متاح في التخزين الخاص'], 409);
            }
            if (DB::table('jabalia_teacher_contract_periods')
                ->where('contract_document_id', $doc->id)->exists()) {
                return response()->json(['error' => 'هذا العقد مسجل بالفعل؛ استخدم مستندًا جديدًا للتجديد'], 409);
            }

            $previousId = $data['previous_period_id'] ?? null;
            if ($previousId !== null) {
                $previous = DB::table('jabalia_teacher_contract_periods')
                    ->where('id', $previousId)
                    ->where('organization_id', $org->id)
                    ->where('school_id', $school)->where('teacher_id', $teacher)
                    ->lockForUpdate()->first();
                if (!$previous) return response()->json(['error' => 'السجل السابق غير موجود'], 404);
                if (DB::table('jabalia_teacher_contract_periods')
                    ->where('previous_period_id', $previousId)->exists()) {
                    return response()->json(['error' => 'سجل العقد السابق مرتبط بتجديد بالفعل'], 409);
                }
                if ($data['starts_on'] < $previous->ends_on) {
                    return response()->json(['error' => 'تاريخ بداية التجديد أقدم من نهاية العقد السابق'], 422);
                }
            }

            $id = DB::table('jabalia_teacher_contract_periods')->insertGetId([
                'organization_id' => $org->id,
                'school_id' => $school,
                'teacher_id' => $teacher,
                'contract_document_id' => $doc->id,
                'previous_period_id' => $previousId,
                'project_name' => $data['project_name'],
                'starts_on' => $data['starts_on'],
                'ends_on' => $data['ends_on'],
                'signed_on' => $data['signed_on'] ?? null,
                'recorded_by' => $request->attributes->get('jwt_user')->id,
                'created_at' => now(),
            ]);

            $this->audit($request, $org, $school, $teacher, $doc->id, 'contract_period_recorded');
            return response()->json([
                'period' => [
                    'id' => $id,
                    'contract_document_id' => (int) $doc->id,
                    'previous_period_id' => $previousId,
                    'project_name' => $data['project_name'],
                    'starts_on' => $data['starts_on'],
                    'ends_on' => $data['ends_on'],
                    'signed_on' => $data['signed_on'] ?? null,
                ],
                'immutable' => true,
                'employment_legally_verified' => false,
            ], 201);
        });
    }
}
