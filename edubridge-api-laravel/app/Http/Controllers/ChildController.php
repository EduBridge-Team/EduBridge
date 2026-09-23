<?php

namespace App\Http\Controllers;

// مسارات الأطفال
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;
use App\Http\Controllers\Concerns\ChildControllerHelpers;

class ChildController extends Controller
{
    use ChildControllerHelpers;

    // الحقول النصية الاختيارية التي يرسلها التطبيق/الموقع في لوحة ولي الأمر
    private const TEXT_FIELDS = [
        'disability_type',
        'disability_description',
        'special_needs',
        'preferred_learning_style',
        'notes',
    ];

    // حقول توثيق الهوية وصلة القرابة (البطاقة 1)
    private const IDENTITY_FIELDS = [
        'child_national_id',
        'guardian_national_id',
        'guardian_id_document_url',
        'kinship_document_url',
    ];

    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || !in_array($user->role, ['parent', 'admin'], true)) {
            return response()->json(['error' => 'إضافة طفل متاحة لولي الأمر والأدمن فقط'], 403);
        }
        if (!$request->input('name')) {
            return response()->json(['error' => 'اسم الطفل مطلوب'], 400);
        }

        // نبني الحمولة من الحقول المرسلة فقط (نتجاهل غير الموجود)
        $data = ['name' => $request->input('name')];

        foreach (['age', 'birth_date', 'gender', 'disability_type_id', 'organization_id'] as $f) {
            if ($request->has($f) && $request->input($f) !== null) {
                $data[$f] = $request->input($f);
            }
        }
        foreach (self::TEXT_FIELDS as $f) {
            if ($request->has($f) && $request->input($f) !== null) {
                $data[$f] = $request->input($f);
            }
        }
        foreach (self::IDENTITY_FIELDS as $f) {
            if ($request->has($f) && $request->input($f) !== null) {
                $value = $request->input($f);
                if (in_array($f, ['guardian_id_document_url', 'kinship_document_url'], true)
                    && !$this->validateDocumentUrl($user, is_string($value) ? $value : null)) {
                    return response()->json(['error' => 'مستندات الطفل يجب رفعها من حسابك عبر التخزين الآمن'], 422);
                }
                $data[$f] = $value;
            }
        }
        foreach (['strengths', 'challenges'] as $f) {
            if ($request->has($f) && $request->input($f) !== null) {
                $data[$f] = json_encode($request->input($f), JSON_UNESCAPED_UNICODE);
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

            return response()->json(['child' => $this->decodeChild(DB::table('children')->find($id))], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // عرض الأطفال
    // - ولي الأمر: يشوف أطفاله فقط
    // - المعلّم/المختص/الأدمن: يشوفوا الكل
    // GET /api/children
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            // نُرفق اسم نوع الإعاقة واسم المعلّم المسؤول لعرضهما في اللوحات
            $base = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('users as tu', 'tu.id', '=', 'c.assigned_teacher_id')
                ->select('c.*', 'dt.name as disability_name', 'tu.name as assigned_teacher_name')
                ->orderBy('c.name');

            if ($user->role === 'parent') {
                $children = (clone $base)
                    ->join('child_parent as cp', 'cp.child_id', '=', 'c.id')
                    ->where('cp.parent_id', $user->id)
                    ->get();
            } else {
                $children = $base->get();
            }

            $children = $children->map(
                fn ($c) => $this->hideIdentityFieldsForStaff(
                    $this->attachSpecialists($this->decodeChild($c)),
                    $user
                )
            );

            return response()->json(['children' => $children]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // عرض طفل واحد بالتفصيل (مع اسم نوع الإعاقة والمعلّم المسؤول والمؤسسة)
    // GET /api/children/:id
    public function show(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $child = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('users as tu', 'tu.id', '=', 'c.assigned_teacher_id')
                ->leftJoin('organizations as o', 'o.id', '=', 'c.organization_id')
                ->where('c.id', $id)
                ->select('c.*', 'dt.name as disability_name', 'tu.name as assigned_teacher_name', 'o.name as organization_name')
                ->first();

            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }
            $child = $this->hideIdentityFieldsForStaff(
                $this->attachSpecialists($this->decodeChild($child)),
                $user
            );

            return response()->json(['child' => $child]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تعديل بيانات طفل
    // - ولي الأمر: بيانات طفله ووثائقه فقط
    // - المعلّم/المختص: البيانات التعليمية فقط للطفل المصرّح له
    // - الأدمن: كامل الحقول
    // PUT /api/children/:id
    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $child = DB::table('children')->where('id', $id)->first();
            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            // ولي الأمر لا يعدّل إلا أطفاله المرتبطين به
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
            foreach (['age', 'birth_date', 'gender', 'disability_type_id'] as $f) {
                if ($request->has($f)) {
                    $data[$f] = $request->input($f);
                }
            }
            foreach (['organization_id', 'status', 'assigned_teacher_id'] as $f) {
                if ($request->has($f)) {
                    if ($user->role !== 'admin') {
                        return response()->json(['error' => 'هذا الحقل إداري فقط'], 403);
                    }

                    $value = $request->input($f);
                    if ($f === 'assigned_teacher_id' && $value !== null
                        && !DB::table('users')->where('id', $value)->where('role', 'teacher')->exists()) {
                        return response()->json(['error' => 'المعلّم غير موجود'], 422);
                    }

                    $data[$f] = $value;
                }
            }
            foreach (self::TEXT_FIELDS as $f) {
                if ($request->has($f)) {
                    $data[$f] = $request->input($f);
                }
            }
            foreach (self::IDENTITY_FIELDS as $f) {
                if ($request->has($f)) {
                    if (!in_array($user->role, ['parent', 'admin'], true)) {
                        return response()->json(['error' => 'تعديل بيانات التوثيق متاح لولي الأمر والأدمن فقط'], 403);
                    }
                    $value = $request->input($f);
                    if (in_array($f, ['guardian_id_document_url', 'kinship_document_url'], true)
                        && !$this->validateDocumentUrl(
                            $user,
                            is_string($value) ? $value : null,
                            isset($child->$f) ? (string) $child->$f : null
                        )) {
                        return response()->json(['error' => 'مستندات الطفل يجب رفعها من حسابك عبر التخزين الآمن'], 422);
                    }
                    $data[$f] = $value;
                }
            }
            // إعادة رفع مستندات جديدة تعيد حالة التوثيق إلى "بانتظار المراجعة"
            $identityChanged = false;
            foreach (self::IDENTITY_FIELDS as $f) {
                if ($request->has($f)) {
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
            foreach (['strengths', 'challenges'] as $f) {
                if ($request->has($f)) {
                    $val = $request->input($f);
                    $data[$f] = $val === null ? null : json_encode($val, JSON_UNESCAPED_UNICODE);
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

    // حذف طفل (أدمن فقط)
    // DELETE /api/children/:id
    public function destroy(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        if (!$user || $user->role !== 'admin') {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $deleted = DB::transaction(function () use ($id) {
                $child = DB::table('children')->where('id', $id)->first();
                if (!$child) {
                    return false;
                }

                // علاقات الطفل في المخطط تستخدم ON DELETE CASCADE.
                DB::table('children')->where('id', $id)->delete();

                return true;
            });

            if (!$deleted) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            return response()->json(['message' => 'تم حذف الطفل بنجاح']);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'تعذّر حذف الطفل'], 500);
        }
    }

    // ربط طفل بولي أمر
    // POST /api/children/:id/parents   body: { parent_id }
}
