<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildUpdateActions
{
    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['parent', 'teacher', 'specialist', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }
        if ($user->role === 'specialist' && !DB::table('child_specialist')
            ->where('child_id', $id)->where('specialist_id', $user->id)->exists()) {
            return response()->json(['error' => 'يمكنك تعديل الأطفال المعيّنين لك فقط'], 403);
        }

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

            if ($user->role === 'teacher') {
                $forbidden = array_merge(
                    ['age', 'birth_date', 'gender', 'disability_type_id', 'strengths', 'challenges'],
                    self::TEXT_FIELDS,
                    self::IDENTITY_FIELDS
                );
                foreach ($forbidden as $field) {
                    if ($request->has($field)) {
                        return response()->json(['error' => 'المعلم لا يملك صلاحية تعديل هذا الحقل'], 403);
                    }
                }
            }

            if ($user->role === 'specialist') {
                foreach (array_merge(
                    ['name', 'age', 'birth_date', 'gender', 'disability_type_id'],
                    self::IDENTITY_FIELDS
                ) as $field) {
                    if ($request->has($field)) {
                        return response()->json(['error' => 'المختص لا يملك صلاحية تعديل هذا الحقل'], 403);
                    }
                }
            }

            $data = [];

            // Keep the existing teacher rename flow, but block broader demographic/profile edits.
            if (in_array($user->role, ['parent', 'teacher', 'admin'], true)
                && $request->has('name') && $request->input('name') !== null) {
                $data['name'] = $request->input('name');
            }

            if (in_array($user->role, ['parent', 'admin'], true)) {
                foreach (['age', 'birth_date', 'gender', 'disability_type_id'] as $field) {
                    if ($request->has($field)) {
                        $data[$field] = $request->input($field);
                    }
                }
            }

            $adminError = $this->collectAdminChildUpdates($request, $user, $data);
            if ($adminError) {
                return $adminError;
            }

            // Educational/adaptation observations may be maintained by an assigned specialist.
            if (in_array($user->role, ['parent', 'specialist', 'admin'], true)) {
                foreach (self::TEXT_FIELDS as $field) {
                    if ($request->has($field)) {
                        $data[$field] = $request->input($field);
                    }
                }

                foreach (['strengths', 'challenges'] as $field) {
                    if ($request->has($field)) {
                        $value = $request->input($field);
                        $data[$field] = $value === null
                            ? null
                            : json_encode($value, JSON_UNESCAPED_UNICODE);
                    }
                }
            }

            if (in_array($user->role, ['parent', 'admin'], true)) {
                $identityError = $this->collectIdentityChildUpdates(
                    $request,
                    $user,
                    $child,
                    $data
                );
                if ($identityError) {
                    return $identityError;
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
