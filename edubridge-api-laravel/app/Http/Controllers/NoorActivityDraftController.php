<?php

namespace App\Http\Controllers;

use App\Services\Noor\StudentActivityDraftService;
use App\Services\Noor\StudentContextService;
use Illuminate\Http\Request;
use RuntimeException;

class NoorActivityDraftController extends Controller
{
    public function store(Request $request, int $child, StudentContextService $contexts, StudentActivityDraftService $activities)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) return response()->json(['error' => 'غير مصرح.'], 401);
        if (($user->role ?? null) !== 'teacher') {
            return response()->json(['error' => 'مسودة النشاط متاحة للمعلم فقط.'], 403);
        }
        $data = $request->validate([
            'topic' => ['required', 'string', 'min:3', 'max:160'],
            'duration_minutes' => ['required', 'integer', 'between:5,90'],
        ]);
        // StudentContextService checks assigned-teacher access and limits disclosed fields.
        $context = $contexts->build($child, $user);
        try {
            $draft = $activities->generate($context, $data['topic'], (int) $data['duration_minutes']);
        } catch (RuntimeException $e) {
            $status = str_contains($e->getMessage(), 'غير مفعّل') ? 503 : 502;
            if (str_contains($e->getMessage(), 'مشغول')) $status = 429;
            return response()->json(['error' => $e->getMessage()], $status);
        }
        return response()->json([
            'draft' => $draft,
            'requires_review' => true,
            'auto_published' => false,
        ]);
    }
}
