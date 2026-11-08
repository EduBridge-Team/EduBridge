<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JabaliaSupervisorVisitController extends Controller
{
    private function scope(Request $request, string $slug, int $school): ?object
    {
        $organization = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if ($slug !== 'jabalia' || ($organization->slug ?? null) !== 'jabalia'
            || ($actor->role ?? null) !== 'institution') {
            return null;
        }

        return DB::table('schools')
            ->where('id', $school)->where('organization_id', $organization->id)->first();
    }

    public function index(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->scope($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $org = $request->attributes->get('organization');
        $visits = DB::table('jabalia_supervisor_visits')
            ->where('organization_id', $org->id)->where('school_id', $school)
            ->orderByDesc('visited_on')->orderByDesc('id')->paginate(25);

        $recentEvents = DB::table('jabalia_supervisor_visit_events')
            ->where('organization_id', $org->id)->where('school_id', $school)
            ->orderByDesc('id')->limit(100)
            ->get(['id', 'visit_id', 'action', 'from_status', 'to_status', 'note', 'actor_id', 'created_at']);

        return response()->json([
            'visits' => $visits,
            'recent_events' => $recentEvents,
            'note' => 'سجل متابعة تشغيلي، وليس نموذجًا رسميًا معتمدًا من الجمعية',
        ]);
    }

    public function store(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->scope($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'visited_on' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            'supervisor_name' => ['required', 'string', 'min:2', 'max:160'],
            'findings' => ['required', 'string', 'min:3', 'max:4000'],
            'corrective_action' => ['required', 'string', 'min:3', 'max:4000'],
            'due_on' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:visited_on'],
        ]);

        foreach (['supervisor_name', 'findings', 'corrective_action'] as $field) {
            $data[$field] = trim($data[$field]);
            if (mb_strlen($data[$field]) < ($field === 'supervisor_name' ? 2 : 3)) {
                return response()->json(['error' => 'البيانات المطلوبة غير مكتملة'], 422);
            }
        }

        $org = $request->attributes->get('organization');
        $actorId = $request->attributes->get('jwt_user')->id;

        return DB::transaction(function () use ($org, $school, $data, $actorId) {
            // Keep the same school-first lock order as Jabalia school operations.
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            $id = DB::table('jabalia_supervisor_visits')->insertGetId([
                'organization_id' => $org->id,
                'school_id' => $school,
                ...$data,
                'status' => 'open',
                'recorded_by' => $actorId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            DB::table('jabalia_supervisor_visit_events')->insert([
                'visit_id' => $id,
                'organization_id' => $org->id,
                'school_id' => $school,
                'action' => 'created',
                'from_status' => null,
                'to_status' => 'open',
                'note' => null,
                'actor_id' => $actorId,
                'created_at' => now(),
            ]);
            return response()->json([
                'visit' => DB::table('jabalia_supervisor_visits')->where('id', $id)->first(),
            ], 201);
        });
    }

    public function updateStatus(
        Request $request, string $organizationSlug, int $school, int $visit
    ): JsonResponse {
        if (!$this->scope($request, $organizationSlug, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'expected_status' => ['required', 'in:open,completed'],
            'status' => ['required', 'in:open,completed'],
            'note' => ['required', 'string', 'min:3', 'max:2000'],
        ]);
        $data['note'] = trim($data['note']);
        if (mb_strlen($data['note']) < 3 || $data['status'] === $data['expected_status']) {
            return response()->json(['error' => 'يجب تقديم إجراء متابعة وتغيير الحالة'], 422);
        }

        $org = $request->attributes->get('organization');
        $actorId = $request->attributes->get('jwt_user')->id;

        return DB::transaction(function () use ($org, $school, $visit, $data, $actorId) {
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            $row = DB::table('jabalia_supervisor_visits')
                ->where('id', $visit)->where('school_id', $school)
                ->where('organization_id', $org->id)->lockForUpdate()->first();

            if (!$row) return response()->json(['error' => 'الزيارة غير موجودة'], 404);
            if ($row->status !== $data['expected_status']) {
                return response()->json(['error' => 'تغيرت حالة المتابعة؛ يرجى تحديث السجل'], 409);
            }

            DB::table('jabalia_supervisor_visits')
                ->where('id', $row->id)->where('organization_id', $org->id)
                ->where('school_id', $school)
                ->update(['status' => $data['status'], 'updated_at' => now()]);
            DB::table('jabalia_supervisor_visit_events')->insert([
                'visit_id' => $row->id,
                'organization_id' => $org->id,
                'school_id' => $school,
                'action' => 'status_changed',
                'from_status' => $row->status,
                'to_status' => $data['status'],
                'note' => $data['note'],
                'actor_id' => $actorId,
                'created_at' => now(),
            ]);

            return response()->json([
                'visit' => DB::table('jabalia_supervisor_visits')->where('id', $row->id)->first(),
            ]);
        });
    }
}
