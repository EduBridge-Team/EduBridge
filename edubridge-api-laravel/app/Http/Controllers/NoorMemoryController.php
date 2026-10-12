<?php

namespace App\Http\Controllers;

use App\Services\Noor\MemoryStore;
use App\Services\Noor\StudentContextService;
use Illuminate\Http\Request;

class NoorMemoryController extends Controller
{
    private function authorizeParent(Request $request, int $child, StudentContextService $context): object
    {
        $user = $request->attributes->get('jwt_user');
        abort_unless($user, 401, 'غير مصرح.');
        abort_unless(($user->role ?? '') === 'parent', 403, 'إدارة ذاكرة الطالب متاحة لولي الأمر فقط.');
        // Reuse the existing student assignment policy instead of trusting a supplied child ID.
        $context->build($child, $user);
        abort_unless((int) ($user->id ?? 0) > 0, 403);
        return $user;
    }

    public function index(Request $request, int $child, StudentContextService $context, MemoryStore $store)
    {
        $user = $this->authorizeParent($request, $child, $context);
        $userId = (int) $user->id;
        return response()->json([
            'enabled' => $store->enabled($userId, $child),
            'memories' => $store->list($userId, $child),
        ]);
    }

    public function preferences(Request $request, int $child, StudentContextService $context, MemoryStore $store)
    {
        $user = $this->authorizeParent($request, $child, $context);
        $data = $request->validate(['enabled' => ['required', 'boolean']]);
        $store->setEnabled((int) $user->id, $child, (bool) $data['enabled']);
        return response()->json(['enabled' => $store->enabled((int) $user->id, $child)]);
    }

    public function destroy(Request $request, int $child, int $memory, StudentContextService $context, MemoryStore $store)
    {
        $user = $this->authorizeParent($request, $child, $context);
        abort_unless($store->delete((int) $user->id, $child, $memory), 404, 'الذاكرة غير موجودة.');
        return response()->noContent();
    }
}
