<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class InstitutionSchoolController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $organization = $request->attributes->get('organization');

        $schools = DB::table('schools')
            ->where('organization_id', $organization->id)
            ->orderBy('name')
            ->get();

        return response()->json(['schools' => $schools]);
    }

    public function store(Request $request): JsonResponse
    {
        $organization = $request->attributes->get('organization');

        $data = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'slug' => [
                'required',
                'string',
                'max:80',
                'regex:/^[a-z0-9][a-z0-9-]*$/',
                Rule::unique('schools', 'slug')->where(fn ($query) => $query->where('organization_id', $organization->id)),
            ],
            'address' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:190'],
            'settings' => ['nullable', 'array'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $id = DB::table('schools')->insertGetId([
            'organization_id' => $organization->id,
            'name' => $data['name'],
            'slug' => $data['slug'],
            'address' => $data['address'] ?? null,
            'phone' => $data['phone'] ?? null,
            'email' => $data['email'] ?? null,
            'settings' => json_encode($data['settings'] ?? [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'is_active' => $data['is_active'] ?? true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'school' => DB::table('schools')->where('id', $id)->first(),
        ], 201);
    }

    public function show(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $record = $this->schoolWithinTenant($request, $school);
        if (!$record) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        return response()->json(['school' => $record]);
    }

    public function update(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $organization = $request->attributes->get('organization');
        $record = $this->schoolWithinTenant($request, $school);
        if (!$record) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'slug' => [
                'sometimes',
                'required',
                'string',
                'max:80',
                'regex:/^[a-z0-9][a-z0-9-]*$/',
                Rule::unique('schools', 'slug')
                    ->where(fn ($query) => $query->where('organization_id', $organization->id))
                    ->ignore($school),
            ],
            'address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'email' => ['sometimes', 'nullable', 'email', 'max:190'],
            'settings' => ['sometimes', 'array'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $updates = array_intersect_key($data, array_flip(['name', 'slug', 'address', 'phone', 'email', 'is_active']));
        if (array_key_exists('settings', $data)) {
            $updates['settings'] = json_encode($data['settings'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }
        $updates['updated_at'] = now();

        DB::table('schools')
            ->where('id', $school)
            ->where('organization_id', $organization->id)
            ->update($updates);

        return response()->json([
            'school' => DB::table('schools')->where('id', $school)->first(),
        ]);
    }

    public function destroy(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        $organization = $request->attributes->get('organization');

        $deleted = DB::table('schools')
            ->where('id', $school)
            ->where('organization_id', $organization->id)
            ->delete();

        if (!$deleted) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        return response()->json(['message' => 'تم حذف المدرسة']);
    }

    private function schoolWithinTenant(Request $request, int $school): ?object
    {
        $organization = $request->attributes->get('organization');

        return DB::table('schools')
            ->where('id', $school)
            ->where('organization_id', $organization->id)
            ->first();
    }
}
