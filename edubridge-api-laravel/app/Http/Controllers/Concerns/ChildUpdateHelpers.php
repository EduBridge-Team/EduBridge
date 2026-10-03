<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildUpdateHelpers
{
    private function collectAdminChildUpdates(Request $request, $user, array &$data)
    {
        foreach (['organization_id', 'status', 'assigned_teacher_id'] as $field) {
            if (!$request->has($field)) {
                continue;
            }

            if ($user->role !== 'admin') {
                return response()->json(['error' => 'هذا الحقل إداري فقط'], 403);
            }

            $value = $request->input($field);

            if (
                $field === 'assigned_teacher_id'
                && $value !== null
                && !DB::table('users')->where('id', $value)->where('role', 'teacher')->exists()
            ) {
                return response()->json(['error' => 'المعلّم غير موجود'], 422);
            }

            $data[$field] = $value;
        }

        return null;
    }

    private function collectIdentityChildUpdates(
        Request $request,
        $user,
        $child,
        array &$data
    ) {
        $identityChanged = false;

        foreach (self::IDENTITY_FIELDS as $field) {
            if (!$request->has($field)) {
                continue;
            }

            if (!in_array($user->role, ['parent', 'admin'], true)) {
                return response()->json([
                    'error' => 'تعديل بيانات التوثيق متاح لولي الأمر والأدمن فقط',
                ], 403);
            }

            $value = $request->input($field);
            $identityChanged = $identityChanged || (string) ($child->$field ?? '') !== (string) ($value ?? '');

            if (
                in_array($field, ['guardian_id_document_url', 'kinship_document_url', 'medical_report_url'], true)
                && !$this->validateDocumentUrl(
                    $user,
                    is_string($value) ? $value : null,
                    isset($child->$field) ? (string) $child->$field : null
                )
            ) {
                return response()->json([
                    'error' => 'مستندات الطفل يجب رفعها من حسابك عبر التخزين الآمن',
                ], 422);
            }

            $data[$field] = $value;
        }

        if ($identityChanged && $user->role !== 'admin') {
            $data['doc_verification_status'] = 'pending';
        }

        if ($request->has('doc_verification_status') && $user->role !== 'admin') {
            return response()->json(['error' => 'تغيير حالة التوثيق متاح للأدمن فقط'], 403);
        }

        if ($request->has('doc_verification_status') && $user->role === 'admin') {
            $data['doc_verification_status'] = $request->input('doc_verification_status');
        }

        return null;
    }
}
