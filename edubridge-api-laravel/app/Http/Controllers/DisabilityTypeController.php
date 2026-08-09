<?php

namespace App\Http\Controllers;

// أنواع الإعاقة — قائمة مرجعية تستعملها الواجهات (اختيار نوع الدرس، عرض احتياج الطفل)
use Illuminate\Support\Facades\DB;

class DisabilityTypeController extends Controller
{
    // GET /api/disability-types
    public function index()
    {
        try {
            $types = DB::table('disability_types')
                ->select('id', 'name', 'description')
                ->orderBy('name')
                ->get();

            return response()->json(['disability_types' => $types]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
