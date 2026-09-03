<?php

namespace App\Http\Controllers;

// مسارات الأطفال
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;

class ChildController extends Controller
{
    // الحقول النصية الاختيارية التي يرسلها التطبيق/الموقع في لوحة ولي الأمر
    private const TEXT_FIELDS = [
        'disability_type',
        'disability_description',
        'medical_history',
        'psychologist_notes',
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

    // فكّ ترميز أعمدة JSON (نقاط القوة/التحديات) وإرجاعها كمصفوفات
    private function decodeChild($child)
    {
        if (!$child) {
            return $child;
        }
        foreach (['strengths', 'challenges'] as $key) {
            if (isset($child->$key) && is_string($child->$key)) {
                $child->$key = json_decode($child->$key, true);
            }
        }
        // للتوافق: لو ما فيه نوع إعاقة نصّي نستعمل اسم النوع من القائمة المرجعية
        if (empty($child->disability_type) && !empty($child->disability_name)) {
            $child->disability_type = $child->disability_name;
        }
        return $child;
    }

    // إضافة طفل (ولي أمر / معلّم / مختص / أدمن)
    // POST /api/children
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

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
                $data[$f] = $request->input($f);
            }
        }
        foreach (['strengths', 'challenges'] as $f) {
            if ($request->has($f) && $request->input($f) !== null) {
                $data[$f] = json_encode($request->input($f), JSON_UNESCAPED_UNICODE);
            }
        }

        try {
            $id = DB::table('children')->insertGetId($data);

            // ولي الأمر يُربط تلقائياً بالطفل الذي أضافه
            if ($user && $user->role === 'parent') {
                DB::table('child_parent')->insertOrIgnore([
                    'child_id' => $id,
                    'parent_id' => $user->id,
                ]);
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

            $children = $children->map(fn ($c) => $this->decodeChild($c));

            return response()->json(['children' => $children]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // عرض طفل واحد بالتفصيل (مع اسم نوع الإعاقة والمعلّم المسؤول والمؤسسة)
    // GET /api/children/:id
    public function show($id)
    {
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
            return response()->json(['child' => $this->decodeChild($child)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تعديل بيانات طفل
    // - ولي الأمر: أطفاله فقط
    // - المعلّم/المختص/الأدمن: أي طفل
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
            foreach (['age', 'birth_date', 'gender', 'disability_type_id', 'organization_id', 'status', 'assigned_teacher_id'] as $f) {
                if ($request->has($f)) {
                    $data[$f] = $request->input($f);
                }
            }
            foreach (self::TEXT_FIELDS as $f) {
                if ($request->has($f)) {
                    $data[$f] = $request->input($f);
                }
            }
            foreach (self::IDENTITY_FIELDS as $f) {
                if ($request->has($f)) {
                    $data[$f] = $request->input($f);
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

            return response()->json(['child' => $this->decodeChild(DB::table('children')->find($id))]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // ربط طفل بولي أمر
    // POST /api/children/:id/parents   body: { parent_id }
    public function addParent(Request $request, $id)
    {
        $parentId = $request->input('parent_id');
        if (!$parentId) {
            return response()->json(['error' => 'parent_id مطلوب'], 400);
        }

        try {
            // إدراج مع تجاهل التكرار (ON CONFLICT DO NOTHING)
            DB::table('child_parent')->insertOrIgnore([
                'child_id' => $id,
                'parent_id' => $parentId,
            ]);

            $child = DB::table('children')->where('id', $id)->first();
            Notify::toUser(
                $parentId,
                'تمت إضافة طفل',
                'تمت إضافة الطفل ' . ($child->name ?? '') . ' إلى حسابك',
                'child_added'
            );

            return response()->json(['message' => 'تم الربط'], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تعيين معلّم مسؤول عن الطفل (معلّم / مختص / أدمن)
    // POST /api/children/:id/assign-teacher   body: { teacher_id }
    public function assignTeacher(Request $request, $id)
    {
        $teacherId = $request->input('teacher_id');
        if (!$teacherId) {
            return response()->json(['error' => 'teacher_id مطلوب'], 400);
        }

        try {
            if (!DB::table('children')->where('id', $id)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }
            if (!DB::table('users')->where('id', $teacherId)->where('role', 'teacher')->exists()) {
                return response()->json(['error' => 'المعلّم غير موجود'], 404);
            }

            DB::table('children')->where('id', $id)->update([
                'assigned_teacher_id' => $teacherId,
                'status' => 'assigned',
            ]);

            // إشعار أولياء أمر الطفل بتعيين المعلّم
            $child = DB::table('children')->where('id', $id)->first();
            $teacher = DB::table('users')->where('id', $teacherId)->first();
            Notify::toChildParents(
                $id,
                'تم تعيين معلّم',
                'تم تعيين المعلّم ' . ($teacher->name ?? '') . ' للطفل ' . ($child->name ?? ''),
                'child_assigned'
            );

            return response()->json(['child' => $this->decodeChild(DB::table('children')->find($id))]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // الدروس المناسبة لطفل معيّن (حسب نوع إعاقته) — جوهر الفكرة
    // GET /api/children/:id/lessons
    public function lessons($id)
    {
        try {
            $lessons = DB::table('lessons as l')
                ->join('children as c', 'c.disability_type_id', '=', 'l.disability_type_id')
                ->where('c.id', $id)
                ->orderByDesc('l.created_at')
                ->select('l.*')
                ->get();

            return response()->json(['lessons' => $lessons]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
