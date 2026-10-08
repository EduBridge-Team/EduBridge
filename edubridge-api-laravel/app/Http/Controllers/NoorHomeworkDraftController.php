<?php

namespace App\Http\Controllers;

use App\Services\Noor\StudentContextService;
use App\Services\Noor\StudentHomeworkDraftService;
use Illuminate\Http\Request;
use RuntimeException;

class NoorHomeworkDraftController extends Controller
{
    public function store(
        Request $request,
        int $child,
        StudentContextService $contextService,
        StudentHomeworkDraftService $draftService,
    ) {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'غير مصرح.'], 401);
        }

        if (($user->role ?? null) !== 'teacher') {
            return response()->json(['error' => 'إنشاء مسودة الواجب متاح للمعلم فقط.'], 403);
        }

        $validated = $request->validate([
            'focus' => ['nullable', 'string', 'max:500'],
        ]);

        $context = $contextService->build($child, $user);

        try {
            $draft = $draftService->generate($context, $validated['focus'] ?? null);
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
