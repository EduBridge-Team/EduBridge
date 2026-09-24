<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait SpecialistSuggestionHelpers
{
    private function suggestionQuery()
    {
        return DB::table('specialist_suggestions as ss')
            ->join('children as c', 'c.id', '=', 'ss.child_id')
            ->join('users as s', 's.id', '=', 'ss.specialist_id')
            ->leftJoin('users as by', 'by.id', '=', 'ss.suggested_by')
            ->select(
                'ss.*',
                'c.name as child_name',
                's.name as specialist_name',
                'by.name as suggested_by_name'
            );
    }

    private function findSuggestion(int $id)
    {
        return $this->suggestionQuery()->where('ss.id', $id)->first();
    }
}
