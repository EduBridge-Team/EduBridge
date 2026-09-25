<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;

trait SpecialistSuggestionResponseActions
{
    public function accept(Request $request, $id)
    {
        return $this->respond($request, (int) $id, true);
    }

    public function reject(Request $request, $id)
    {
        return $this->respond($request, (int) $id, false);
    }

    private function respond(Request $request, int $id, bool $accept)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $rejectionReason = trim((string) $request->input('reason', ''));

        try {
            $result = $this->processSuggestionResponse($user, $id, $accept, $rejectionReason);

            if (($result['status'] ?? 500) === 200) {
                $this->notifySuggestionResponse($result['body']['suggestion'], $accept);
            }

            return response()->json($result['body'], $result['status']);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر معالجة الاقتراح'], 500);
        }
    }
}
