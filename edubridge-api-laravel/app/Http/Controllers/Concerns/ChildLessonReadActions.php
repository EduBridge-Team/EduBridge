<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ChildLessonReadActions
{
    public function lessons(Request $request, $id)
    {
        try {
            $child = DB::table('children')->where('id', $id)->first();
            if (!$child) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            $lessons = DB::table('lessons as l')
                ->where(function ($query) use ($child, $id) {
                    $query
                        ->whereNull('l.target_type')
                        ->orWhere('l.target_type', 'everyone')
                        ->orWhere(function ($byDisability) use ($child) {
                            $byDisability->where('l.target_type', 'byDisability')
                                ->where('l.disability_type_id', $child->disability_type_id);
                        })
                        ->orWhere(function ($specificChildren) use ($id) {
                            $specificChildren->where('l.target_type', 'specificChildren')
                                ->whereJsonContains('l.target_child_ids', (int) $id);
                        });
                })
                ->orderByDesc('l.created_at')
                ->select('l.*')
                ->get()
                ->map(fn ($lesson) => $this->serializeChildLesson($request, $lesson));

            return response()->json(['lessons' => $lessons]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
