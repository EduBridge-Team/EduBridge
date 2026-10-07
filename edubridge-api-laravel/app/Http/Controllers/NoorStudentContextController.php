<?php

namespace App\Http\Controllers;

use App\Services\Noor\StudentContextService;
use Illuminate\Http\Request;

class NoorStudentContextController extends Controller
{
    public function show(Request $request, int $child, StudentContextService $service)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'غير مصرح.'], 401);
        }

        $context = $service->build($child, $user);

        return response()->json([
            'context' => $context,
            'prompt_context' => $service->toPromptContext($context),
        ]);
    }
}
