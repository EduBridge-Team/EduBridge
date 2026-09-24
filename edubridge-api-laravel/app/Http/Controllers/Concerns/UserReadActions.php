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
            $query = DB::table('users')
                ->select(
                    'id',
                    'name',
                    'email',
                    'role',
                    'phone',
                    'verification_status',
                    'verified_at',
                    'created_at'
                )
                ->orderBy('name');

            if ($user->role === 'admin') {
                $query->addSelect('national_id');
                $role = $request->query('role');
                if ($role) {
                    $query->where('role', $role);
                }
            } elseif (in_array($user->role, ['ministry', 'institution'], true)) {
                $role = $request->query('role');
                if ($role) {
                    $query->where('role', $role);
                }
            } elseif ($user->role === 'parent') {
                $query = DB::table('users')
                    ->select('id', 'name', 'email', 'role', 'phone', 'verification_status')
                    ->whereIn('role', ['teacher', 'specialist'])
                    ->orderBy('name');
            } else {
                $query = DB::table('users')
                    ->select('id', 'name', 'email', 'role', 'phone', 'verification_status')
                    ->whereIn('role', ['teacher', 'specialist', 'admin', 'ministry', 'institution'])
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
}
