<?php

namespace App\Http\Controllers;

// مسارات الأطفال
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChildController extends Controller
{
    // إضافة طفل (معلّم / مختص / أدمن)
    // POST /api/children
    public function store(Request $request)
    {
        if (!$request->input('name')) {
            return response()->json(['error' => 'اسم الطفل مطلوب'], 400);
        }

        try {
            $id = DB::table('children')->insertGetId([
                'name' => $request->input('name'),
                'birth_date' => $request->input('birth_date'),
                'gender' => $request->input('gender'),
                'disability_type_id' => $request->input('disability_type_id'),
                'organization_id' => $request->input('organization_id'),
                'notes' => $request->input('notes'),
            ]);

            return response()->json(['child' => DB::table('children')->find($id)], 201);
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
            // نُرفق اسم نوع الإعاقة (disability_name) لتستعمله لوحات المعلّم والمختص
            $base = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->select('c.*', 'dt.name as disability_name')
                ->orderBy('c.name');

            if ($user->role === 'parent') {
                $children = (clone $base)
                    ->join('child_parent as cp', 'cp.child_id', '=', 'c.id')
                    ->where('cp.parent_id', $user->id)
                    ->get();
            } else {
                $children = $base->get();
            }

            return response()->json(['children' => $children]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // عرض طفل واحد بالتفصيل (مع اسم نوع الإعاقة والمؤسسة)
    // GET /api/children/:id
    public function show($id)
    {
        try {
            $child = DB::table('children as c')
                ->leftJoin('disability_types as dt', 'dt.id', '=', 'c.disability_type_id')
                ->leftJoin('organizations as o', 'o.id', '=', 'c.organization_id')
                ->where('c.id', $id)
                ->select('c.*', 'dt.name as disability_name', 'o.name as organization_name')
                ->first();

            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }
            return response()->json(['child' => $child]);
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

            return response()->json(['message' => 'تم الربط'], 201);
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
