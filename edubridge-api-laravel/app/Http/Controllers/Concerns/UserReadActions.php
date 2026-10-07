<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait UserReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            if ($user->role === 'admin') {
                $query = DB::table('users')
                    ->select(
                        'id',
                        'name',
                        'email',
                        'role',
                        'phone',
                        'verification_status',
                        'verified_at',
                        'created_at',
                        'national_id'
                    )
                    ->addSelect([
                        'parent_children_count' => DB::table('child_parent as cp')
                            ->join('children as c', 'c.id', '=', 'cp.child_id')
                            ->whereColumn('cp.parent_id', 'users.id')
                            ->selectRaw('COUNT(DISTINCT cp.child_id)'),
                    ])
                    ->orderBy('name');

                $role = $request->query('role');
                if ($role) {
                    $query->where('role', $role);
                }
            } elseif (in_array($user->role, ['ministry', 'institution'], true)) {
                // These roles have dedicated aggregate/domain endpoints and no tenant-safe
                // users-to-organization relation. Do not expose a global user directory.
                $query = DB::table('users')
                    ->select('id', 'name', 'role', 'verification_status')
                    ->whereRaw('1 = 0');
            } elseif ($user->role === 'parent') {
                $query = DB::table('users')
                    ->select('id', 'name', 'role', 'verification_status')
                    ->whereIn('role', ['teacher', 'specialist'])
                    ->whereIn('id', $this->parentCareTeamUserIds((int) $user->id))
                    ->orderBy('name');
            } else {
                // Teacher/specialist workflows need a staff picker, but never the admin,
                // ministry, institution, or parent directory.
                $query = DB::table('users')
                    ->select('id', 'name', 'role', 'verification_status')
                    ->whereIn('role', ['teacher', 'specialist'])
                    ->where('id', '!=', $user->id)
                    ->orderBy('name');
            }

            if (Schema::hasColumn('users', 'specialty')) {
                $query->addSelect('specialty');
            }

            return response()->json(['users' => $query->get()]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    private function parentCareTeamUserIds(int $parentId): array
    {
        if (!Schema::hasTable('child_parent') || !Schema::hasTable('children')) {
            return [];
        }

        $childIds = DB::table('child_parent')
            ->where('parent_id', $parentId)
            ->pluck('child_id');

        if ($childIds->isEmpty()) {
            return [];
        }

        $userIds = collect();

        if (Schema::hasColumn('children', 'assigned_teacher_id')) {
            $userIds = $userIds->merge(
                DB::table('children')
                    ->whereIn('id', $childIds)
                    ->whereNotNull('assigned_teacher_id')
                    ->pluck('assigned_teacher_id')
            );
        }

        if (Schema::hasTable('child_teacher')) {
            $userIds = $userIds->merge(
                DB::table('child_teacher')
                    ->whereIn('child_id', $childIds)
                    ->pluck('teacher_id')
            );
        }

        if (Schema::hasTable('child_specialist')) {
            $userIds = $userIds->merge(
                DB::table('child_specialist')
                    ->whereIn('child_id', $childIds)
                    ->pluck('specialist_id')
            );
        }

        return $userIds
            ->map(fn ($id) => (int) $id)
            ->filter(fn ($id) => $id > 0)
            ->unique()
            ->values()
            ->all();
    }
}
