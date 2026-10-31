<?php

namespace App\Http\Controllers;

use App\Support\SchoolAdministration;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolAdministrationDirectoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        if (($request->attributes->get('jwt_user')->role ?? null) !== 'admin') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $data = $request->validate(['after_id' => ['sometimes', 'integer', 'min:0']]);
        $rows = DB::table('schools')->where('id', '>', $data['after_id'] ?? 0)->orderBy('id')
            ->limit(101)->get(['id', 'name', 'organization_id', 'is_active', 'internal_domain', 'internal_domain_confirmed_at']);
        $page = $rows->take(100)->values();
        return response()->json(['schools' => $page, 'has_more' => $rows->count() > 100,
            'next_after_id' => $rows->count() > 100 ? $page->last()->id : null]);
    }

    public function history(Request $request, int $school): JsonResponse
    {
        $record = DB::table('schools')->find($school);
        $own = SchoolAdministration::directorSchool($request);
        if (!$record || (!SchoolAdministration::mayAppoint($request->attributes->get('jwt_user'), $record)
            && (!$own || (int) $own->id !== $school))) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        return response()->json(['assignments' => DB::table('school_management_assignments as a')
            ->join('users as u', 'u.id', '=', 'a.user_id')->where('a.school_id', $school)
            ->orderByDesc('a.id')->limit(100)->get(['a.id', 'a.user_id', 'u.name', 'u.email', 'a.role', 'a.starts_at', 'a.ends_at'])]);
    }
}
