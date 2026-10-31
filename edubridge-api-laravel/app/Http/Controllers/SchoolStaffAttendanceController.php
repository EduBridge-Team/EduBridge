<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolStaffAttendanceController extends Controller
{
    private function roster(int $school): \Illuminate\Database\Query\Builder
    {
        return DB::table('users as u')->where('u.role', '!=', 'student')->where(function ($q) use ($school) {
            $q->whereIn('u.id', DB::table('school_internal_identities')->where('school_id', $school)->where('is_active', true)->select('user_id'))
                ->orWhereIn('u.id', DB::table('school_management_assignments')->where('school_id', $school)->whereNull('ends_at')->select('user_id'));
        });
    }

    public function index(Request $request, string $slug, int $school): JsonResponse
    {
        $scope = SchoolScopedAccess::resolve($request, 'attendance');
        if (!$scope || (int) $scope->id !== $school) return response()->json(['error' => 'Forbidden'], 403);
        $data = $request->validate(['date' => ['required', 'date_format:Y-m-d']]);
        return response()->json(['date' => $data['date'], 'staff' => $this->roster($school)->orderBy('u.name')->get(['u.id', 'u.name', 'u.role']),
            'records' => DB::table('school_staff_attendance')->where('school_id', $school)->where('attendance_date', $data['date'])
                ->get(['user_id', 'status'])]);
    }

    public function mark(Request $request, string $slug, int $school): JsonResponse
    {
        return DB::transaction(function () use ($request, $school) {
            $scope = SchoolScopedAccess::resolve($request, 'attendance');
            if (!$scope || (int) $scope->id !== $school) return response()->json(['error' => 'Forbidden'], 403);
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            $data = $request->validate(['date' => ['required', 'date_format:Y-m-d'],
                'records' => ['required', 'array', 'min:1', 'max:500'],
                'records.*.user_id' => ['required', 'integer', 'distinct'],
                'records.*.status' => ['required', 'in:present,absent,late,excused']]);
            $allowed = $this->roster($school)->pluck('u.id')->map(fn ($id) => (int) $id)->all();
            foreach ($data['records'] as $record) {
                if (!in_array((int) $record['user_id'], $allowed, true)) return response()->json(['error' => 'Staff member unavailable'], 422);
            }
            $rows = array_map(fn ($record) => ['school_id' => $school, 'user_id' => $record['user_id'],
                'attendance_date' => $data['date'], 'status' => $record['status'],
                'recorded_by' => $request->attributes->get('jwt_user')->id, 'created_at' => now(), 'updated_at' => now()], $data['records']);
            DB::table('school_staff_attendance')->upsert($rows, ['school_id', 'user_id', 'attendance_date'], ['status', 'recorded_by', 'updated_at']);
            return response()->json(['saved' => true, 'count' => count($rows)]);
        }, 3);
    }
}
