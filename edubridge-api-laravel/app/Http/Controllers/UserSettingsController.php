<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserSettingsController extends Controller
{
    public function show(Request $request)
    {
        $jwtUser = $request->attributes->get('jwt_user');
        $userId = (int) ($jwtUser->id ?? 0);

        $settings = DB::table('user_settings')
            ->where('user_id', $userId)
            ->first();

        return response()->json([
            'settings' => [
                'theme_mode' => $settings->theme_mode ?? 'light',
                'assistant_visible' => isset($settings->assistant_visible)
                    ? (bool) $settings->assistant_visible
                    : true,
                'microphone_visible' => isset($settings->microphone_visible)
                    ? (bool) $settings->microphone_visible
                    : true,
                'notifications_enabled' => isset($settings->notifications_enabled)
                    ? (bool) $settings->notifications_enabled
                    : true,
            ],
        ]);
    }

    public function update(Request $request)
    {
        $jwtUser = $request->attributes->get('jwt_user');
        $userId = (int) ($jwtUser->id ?? 0);

        $data = $request->validate([
            'theme_mode' => 'sometimes|string|in:light,dark',
            'assistant_visible' => 'sometimes|boolean',
            'microphone_visible' => 'sometimes|boolean',
            'notifications_enabled' => 'sometimes|boolean',
        ]);

        $existing = DB::table('user_settings')
            ->where('user_id', $userId)
            ->first();

        $payload = [
            'theme_mode' => $data['theme_mode'] ?? ($existing->theme_mode ?? 'light'),
            'assistant_visible' => $data['assistant_visible'] ?? ($existing->assistant_visible ?? true),
            'microphone_visible' => $data['microphone_visible'] ?? ($existing->microphone_visible ?? true),
            'notifications_enabled' => $data['notifications_enabled'] ?? ($existing->notifications_enabled ?? true),
            'updated_at' => now(),
        ];

        DB::table('user_settings')->updateOrInsert(
            ['user_id' => $userId],
            $existing ? $payload : array_merge($payload, ['created_at' => now()])
        );

        return $this->show($request);
    }
}
