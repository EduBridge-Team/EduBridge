<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;

trait SpecialistSuggestionReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $status = $request->query('status');
        if ($status !== null && !in_array($status, self::STATUSES, true)) {
            return response()->json(['error' => 'حالة الاقتراح غير صالحة'], 422);
        }

        $query = $this->suggestionQuery();
        if ($user->role === 'specialist') {
            $query->where('ss.specialist_id', $user->id);
        }
        if ($status !== null) {
            $query->where('ss.status', $status);
        }

        return response()->json([
            'suggestions' => $query->orderByDesc('ss.created_at')->get(),
        ]);
    }
}
