<?php

namespace App\Http\Controllers;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SchoolContextController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $school = SchoolScopedAccess::resolve($request, 'context');
        if (!$school) return response()->json(['error' => 'School access is unavailable'], 403);
        return response()->json(['school' => [
            'id' => (int) $school->id, 'name' => $school->name,
            'organization_id' => $school->organization_id === null ? null : (int) $school->organization_id,
        ]]);
    }
}
