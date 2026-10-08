<?php

namespace App\Http\Controllers;

use App\Models\Organization;
use Illuminate\Http\JsonResponse;

class InstitutionContextController extends Controller
{
    public function show(string $slug): JsonResponse
    {
        $organization = Organization::query()
            ->where('slug', $slug)
            ->where('is_active', true)
            ->first();

        if (!$organization) {
            return response()->json(['message' => 'Institution not found.'], 404);
        }

        $settings = $organization->settings ?? [];
        $publicSettings = array_intersect_key($settings, array_flip([
            'display_name', 'login_title', 'login_subtitle', 'locale', 'features',
        ]));

        return response()->json([
            'organization' => [
                'id' => $organization->id,
                'name' => $organization->name,
                'slug' => $organization->slug,
                'domain' => $organization->domain,
                'logo_url' => $organization->logo_url,
                'primary_color' => $organization->primary_color,
                'secondary_color' => $organization->secondary_color,
                'settings' => $publicSettings,
            ],
        ]);
    }
}
