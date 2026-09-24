<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait UploadReadActions
{
    public function showChild(Request $request, int $childId, string $filename)
    {
        $user = $request->attributes->get('jwt_user');
        $allowed = $user && (
            $user->role === 'admin'
            || (
                $user->role === 'parent'
                && DB::table('child_parent')
                    ->where('child_id', $childId)
                    ->where('parent_id', $user->id)
                    ->exists()
            )
        );

        if (!$allowed) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!$this->validFilename($filename)) {
            return response()->json(['error' => 'اسم ملف غير صالح'], 400);
        }

        return $this->streamPrivateObject('child-files/' . $childId . '/' . $filename);
    }

    public function show(Request $request, int $userId, string $filename)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || ($user->role !== 'admin' && (int) $user->id !== $userId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!$this->validFilename($filename)) {
            return response()->json(['error' => 'اسم ملف غير صالح'], 400);
        }

        return $this->streamPrivateObject('user-files/' . $userId . '/' . $filename);
    }
}
