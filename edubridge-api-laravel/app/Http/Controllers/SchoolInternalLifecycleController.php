<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SchoolInternalLifecycleController extends Controller
{
    public function update(Request $request, int $identity): JsonResponse
    {
        return DB::transaction(function () use ($request, $identity) {
            $school = SchoolAdministration::directorSchool($request, true);
            if (!$school) return response()->json(['error' => 'Forbidden'], 403);
            $row = DB::table('school_internal_identities')->where('id', $identity)
                ->where('school_id', $school->id)->lockForUpdate()->first();
            if (!$row) return response()->json(['error' => 'Identity not found'], 404);
            $data = $request->validate([
                'is_active' => ['sometimes', 'required', 'boolean'],
                'password' => ['sometimes', 'required', 'string', 'min:12', 'max:128'],
            ]);
            if (!$data) return response()->json(['error' => 'No changes provided'], 422);
            DB::table('users')->where('id', $row->user_id)->lockForUpdate()->first();
            if (array_key_exists('is_active', $data)) {
                DB::table('school_internal_identities')->where('id', $identity)
                    ->update(['is_active' => $data['is_active'], 'updated_at' => now()]);
            }
            $update = ['updated_at' => now()];
            if (isset($data['password'])) {
                $hash = password_hash($data['password'], PASSWORD_BCRYPT);
                foreach (['password', 'password_hash'] as $column) {
                    if (Schema::hasColumn('users', $column)) $update[$column] = $hash;
                }
            }
            // Invalidate old JWTs on activation changes and password resets.
            if (Schema::hasColumn('users', 'session_version')) $update['session_version'] = DB::raw('session_version + 1');
            DB::table('users')->where('id', $row->user_id)->update($update);
            DB::table('school_administration_events')->insert([
                'school_id' => $school->id, 'actor_id' => $request->attributes->get('jwt_user')->id,
                'action' => isset($data['password']) ? 'internal_password_reset' : 'internal_activation_changed',
                'subject_id' => $row->user_id, 'created_at' => now(),
            ]);
            return response()->json(['updated' => true, 'identity_id' => $identity]);
        }, 3);
    }
}
