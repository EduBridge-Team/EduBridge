<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait HomeworkQueryHelpers
{
    private function homeworkQuery()
    {
        return DB::table('homeworks as h')
            ->join('users as t', 't.id', '=', 'h.teacher_id')
            ->select('h.*', 't.name as teacher_name')
            ->orderByDesc('h.created_at');
    }

    private function normalize($row, ?array $visibleChildIds = null): array
    {
        $data = (array) $row;

        foreach (['assigned_child_ids', 'attachment_urls'] as $field) {
            $value = $data[$field] ?? [];

            if (is_string($value)) {
                $decoded = json_decode($value, true);
                $value = is_array($decoded) ? $decoded : [];
            }

            $data[$field] = array_values(is_array($value) ? $value : []);
        }

        $submissions = DB::table('homework_submissions as hs')
            ->join('children as c', 'c.id', '=', 'hs.child_id')
            ->where('hs.homework_id', $data['id'])
            ->when(
                $visibleChildIds !== null,
                fn ($query) => $query->whereIn('hs.child_id', $visibleChildIds)
            )
            ->orderByDesc('hs.submitted_at')
            ->select('hs.*', 'c.name as child_name')
            ->get()
            ->map(function ($s) {
                $item = (array) $s;
                $urls = $item['file_urls'] ?? [];

                if (is_string($urls)) {
                    $decoded = json_decode($urls, true);
                    $urls = is_array($decoded) ? $decoded : [];
                }

                $item['file_urls'] = array_values(is_array($urls) ? $urls : []);
                $item['file_url'] = $item['file_url'] ?? ($item['file_urls'][0] ?? null);
                $item['is_late'] = (bool) ($item['is_late'] ?? false);

                return $item;
            })
            ->values()
            ->all();

        $data['submissions'] = $submissions;

        return $data;
    }
}
