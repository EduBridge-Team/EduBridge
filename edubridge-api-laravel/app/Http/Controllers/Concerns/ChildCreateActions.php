<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildCreateActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || !in_array($user->role, ['parent', 'admin'], true)) {
            return response()->json(['error' => 'إضافة طفل متاحة لولي الأمر والأدمن فقط'], 403);
        }
        if (!$request->input('name')) {
            return response()->json(['error' => 'اسم الطفل مطلوب'], 400);
        }

        $data = ['name' => $request->input('name')];

        foreach (['age', 'birth_date', 'gender', 'disability_type_id', 'organization_id'] as $field) {
            if ($request->has($field) && $request->input($field) !== null) {
                $data[$field] = $request->input($field);
            }
        }
        foreach (self::TEXT_FIELDS as $field) {
            if ($request->has($field) && $request->input($field) !== null) {
                $data[$field] = $request->input($field);
            }
        }
        foreach (self::IDENTITY_FIELDS as $field) {
            if ($request->has($field) && $request->input($field) !== null) {
                $value = $request->input($field);
                if (in_array($field, ['guardian_id_document_url', 'kinship_document_url'], true)
                    && !$this->validateDocumentUrl($user, is_string($value) ? $value : null)) {
                    return response()->json([
                        'error' => 'مستندات الطفل يجب رفعها من حسابك عبر التخزين الآمن',
                    ], 422);
                }
                $data[$field] = $value;
            }
        }
        foreach (['strengths', 'challenges'] as $field) {
            if ($request->has($field) && $request->input($field) !== null) {
                $data[$field] = json_encode($request->input($field), JSON_UNESCAPED_UNICODE);
            }
        }

        try {
            $id = DB::transaction(function () use ($data, $user) {
                $id = DB::table('children')->insertGetId($data);

                if ($user->role === 'parent') {
                    DB::table('child_parent')->insertOrIgnore([
                        'child_id' => $id,
                        'parent_id' => $user->id,
                    ]);
                }

                return $id;
            });

            if ($user->role === 'parent') {
                Notify::toUser(
                    $user->id,
                    'تمت إضافة طفل',
                    "تمت إضافة الطفل {$data['name']} إلى حسابك بنجاح",
                    'child_added'
                );
            }

            return response()->json([
                'child' => $this->decodeChild(DB::table('children')->find($id)),
            ], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
