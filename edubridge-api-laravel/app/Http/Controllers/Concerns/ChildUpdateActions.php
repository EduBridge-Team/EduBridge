<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildUpdateActions
{
    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $child = DB::table('children')->where('id', $id)->first();
            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            if ($user->role === 'parent') {
                $linked = DB::table('child_parent')
                    ->where('child_id', $id)
                    ->where('parent_id', $user->id)
                    ->exists();

                if (!$linked) {
                    return response()->json(['error' => 'غير مصرّح'], 403);
                }
            }

            $data = [];
            if ($request->has('name') && $request->input('name') !== null) {
                $data['name'] = $request->input('name');
            }

            foreach (['age', 'birth_date', 'gender', 'disability_type_id'] as $field) {
                if ($request->has($field)) {
                    $data[$field] = $request->input($field);
                }
            }

            $adminError = $this->collectAdminChildUpdates($request, $user, $data);
            if ($adminError) {
                return $adminError;
            }

            foreach (self::TEXT_FIELDS as $field) {
                if ($request->has($field)) {
                    $data[$field] = $request->input($field);
                }
            }

            $identityError = $this->collectIdentityChildUpdates(
                $request,
                $user,
                $child,
                $data
            );
            if ($identityError) {
                return $identityError;
            }

            foreach (['strengths', 'challenges'] as $field) {
                if ($request->has($field)) {
                    $value = $request->input($field);
                    $data[$field] = $value === null
                        ? null
                        : json_encode($value, JSON_UNESCAPED_UNICODE);
                }
            }

            if (!empty($data)) {
                DB::table('children')->where('id', $id)->update($data);
            }

            $updatedChild = $this->hideIdentityFieldsForStaff(
                $this->decodeChild(DB::table('children')->find($id)),
                $user
            );

            return response()->json(['child' => $updatedChild]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
