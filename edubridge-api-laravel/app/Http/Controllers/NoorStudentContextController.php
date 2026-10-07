<?php

namespace App\Http\Controllers;

use App\Services\Noor\StudentContextService;
use App\Services\Noor\StudentInsightService;
use Illuminate\Http\Request;

class NoorStudentContextController extends Controller
{
    public function show(
        Request $request,
        int $child,
        StudentContextService $contextService,
        StudentInsightService $insightService,
    ) {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'غير مصرح.'], 401);
        }

        $context = $contextService->build($child, $user);
        $actions = $insightService->actions($context, (string) ($user->role ?? 'user'));
        $context['recommended_actions'] = $actions;

        $actionContext = "الخطوات التعليمية المقترحة من EduBridge مبنية فقط على البيانات المتاحة وليست تشخيصاً:\n".
            json_encode($actions, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $promptContext = mb_substr($actionContext."\n".$contextService->toPromptContext($context), 0, 3900);

        return response()->json([
            'context' => $context,
            'recommended_actions' => $actions,
            'prompt_context' => $promptContext,
        ]);
    }
}
