<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CaseDiscussionLifecycleActions
{
    public function resolve(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $discussion = DB::table('case_discussions')->where('id', $id)->first();

        if (!$discussion) {
            return response()->json(['error' => 'دراسة الحالة غير موجودة'], 404);
        }
        if (!$this->canAccess($user, $discussion)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::table('case_discussions')->where('id', $id)->update([
            'status' => 'resolved',
            'resolved_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['ok' => true]);
    }
}
