<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait MediaReadActions
{
    public function index(Request $request, $lessonId)
    {
        try {
            $media = DB::table('media')
                ->where('lesson_id', $lessonId)
                ->select('id', 'lesson_id', 'type', 'url')
                ->orderBy('id')
                ->get()
                ->map(function ($item) use ($request) {
                    $item->url = $this->absoluteUrl($request, $item->url);

                    return $item;
                });

            return response()->json(['media' => $media]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
