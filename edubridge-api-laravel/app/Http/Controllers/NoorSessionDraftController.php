<?php

namespace App\Http\Controllers;

use App\Services\Noor\StudentContextService;
use App\Services\Noor\StudentSessionDraftService;
use Illuminate\Http\Request;
use RuntimeException;

class NoorSessionDraftController extends Controller
{
    public function store(Request $request, int $child, StudentContextService $contexts, StudentSessionDraftService $sessions)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) return response()->json(['error' => 'غير مصرح.'], 401);
        if (($user->role ?? '') !== 'specialist') {
            return response()->json(['error' => 'إنشاء مسودة الجلسة متاح للمختص فقط.'], 403);
        }

        $data = $request->validate([
            'goal' => ['required', 'string', 'min:3', 'max:160'],
            'duration_minutes' => ['required', 'integer', 'between:10,90'],
        ]);
        // Authorization is checked by the existing specialist-to-child policy.
        $context = $contexts->build($child, $user);

        try {
            $draft = $sessions->generate($context, $data['goal'], (int) $data['duration_minutes']);
        } catch (RuntimeException $e) {
            $status = str_contains($e->getMessage(), 'غير مفعّل') ? 503 : 502;
            if (str_contains($e->getMessage(), 'مشغول')) $status = 429;
            return response()->json(['error' => $e->getMessage()], $status);
        }
        return response()->json(['draft' => $draft, 'requires_review' => true, 'auto_saved' => false]);
    }
}
