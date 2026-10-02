<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

trait LessonMediaBatchLoading
{
    private function loadLessonMedia(Collection $lessons): Collection
    {
        if ($lessons->isEmpty()) {
            return collect();
        }

        return DB::table('media')
            ->whereIn('lesson_id', $lessons->pluck('id'))
            ->select('id', 'lesson_id', 'type', 'url')
            ->orderBy('id')
            ->get()
            ->groupBy('lesson_id');
    }
}
