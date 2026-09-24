<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait WeeklyReportControllerHelpers
{
    private function normalize($row): array
    {
        $data = (array) $row;

        foreach (['achievements', 'concerns'] as $field) {
            $value = $data[$field] ?? [];
            if (is_string($value)) {
                $decoded = json_decode($value, true);
                $value = is_array($decoded) ? $decoded : [];
            }
            $data[$field] = array_values(is_array($value) ? $value : []);
        }

        $data['progress_percentage'] = (float) ($data['progress_percentage'] ?? 0);

        return $data;
    }

    private function reportQuery()
    {
        return DB::table('weekly_reports as wr')
            ->join('children as c', 'c.id', '=', 'wr.child_id')
            ->leftJoin('users as a', 'a.id', '=', 'wr.author_id')
            ->select('wr.*', 'c.name as child_name', 'a.name as author_name');
    }
}
