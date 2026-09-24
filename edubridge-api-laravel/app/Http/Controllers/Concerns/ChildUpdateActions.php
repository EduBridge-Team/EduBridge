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

            foreach (['organization_id', 'status', 'assigned_teacher_id'] as $field) {
                if ($request->has($field)) {
                    if ($user->role !== 'admin') {
                        return response()->json(['error' => 'هذا الحقل إداري فقط'], 403);
                    }

                    $value = $request->input($field);
                    if ($field === 'assigned_teacher_id' && $value !== null
                        && !DB::table('users')->where('id', $value)->where('role', 'teacher')->exists()) {
                        return response()->json(['error' => 'المعلّم غير موجود'], 422);
                    }

                    $data[$field] = $value;
                }
            }

            foreach (self::TEXT_FIELDS as $field) {
                if ($request->has($field)) {
                    $data[$field] = $request->input($field);
                }
            }

            foreach (self::IDENTITY_FIELDS as $field) {
                if ($request->has($field)) {
                    if (!in_array($user->role, ['parent', 'admin'], true)) {
                        return response()->json([
                            'error' => 'تعديل بيانات التوثيق متاح لولي الأمر والأدمن فقط',
                        ], 403);
                    }

                    $value = $request->input($field);
                    if (in_array($field, ['guardian_id_document_url', 'kinship_document_url'], true)
                        && !$this->validateDocumentUrl(
                            $user,
                            is_string($value) ? $value : null,
                            isset($child->$field) ? (string) $child->$field : null
                        )) {
                        return response()->json([
                            'error' => 'مستندات الطفل يجب رفعها من حسابك عبر التخزين الآمن',
                        ], 422);
                    }

                    $data[$field] = $value;
                }
            }

            $identityChanged = false;
            foreach (self::IDENTITY_FIELDS as $field) {
                if ($request->has($field)) {
                    $identityChanged = true;
                    break;
                }
            }

            if ($identityChanged && !$request->has('doc_verification_status')) {
                $data['doc_verification_status'] = 'pending';
            }
            if ($request->has('doc_verification_status') && $user->role === 'admin') {
                $data['doc_verification_status'] = $request->input('doc_verification_status');
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
