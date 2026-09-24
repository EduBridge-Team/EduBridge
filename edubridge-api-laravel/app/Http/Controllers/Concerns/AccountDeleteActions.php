<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait AccountDeleteActions
{
    public function destroy(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || empty($user->id)) {
            return response()->json(['error' => 'المستخدم غير موجود'], 404);
        }

        try {
            $current = DB::table('users')->where('id', $user->id)->value('avatar_url');

            DB::transaction(function () use ($user) {
                $deleted = DB::table('users')->where('id', $user->id)->delete();

                if ($deleted !== 1) {
                    throw new \RuntimeException('Account row was not deleted');
                }
            });

            $this->deleteStoredAvatar($current);

            return response()->json([
                'message' => 'تم حذف الحساب والبيانات المرتبطة به',
                'deleted' => true,
            ]);
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['error' => 'تعذّر حذف الحساب'], 500);
        }
    }
}
