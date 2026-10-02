<?php

namespace App\Support;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

final class ListPage
{
    public static function parameters(Request $request): ?array
    {
        if (!$request->query->has('page') && !$request->query->has('per_page')) return null;
        $data = Validator::make($request->query(), [
            'page' => ['sometimes', 'required', 'integer', 'min:1', 'max:100000'],
            'per_page' => ['sometimes', 'required', 'integer', 'min:1', 'max:100'],
            'q' => ['sometimes', 'nullable', 'string', 'max:200'],
            'active_only' => ['sometimes', 'boolean'],
            'assigned_only' => ['sometimes', 'boolean'],
            'category' => ['sometimes', 'nullable', 'string', 'max:100'],
        ])->validate();
        return ['page' => (int) ($data['page'] ?? 1), 'per_page' => (int) ($data['per_page'] ?? 30)] + $data;
    }

    public static function metadata($paginator): array
    {
        return [
            'page' => $paginator->currentPage(), 'per_page' => $paginator->perPage(),
            'total' => $paginator->total(), 'last_page' => $paginator->lastPage(),
            'has_more' => $paginator->hasMorePages(),
        ];
    }

    public static function search($query, string $text, array $columns): void
    {
        // Treat percent, underscore and the escape character as literal search text.
        $needle = '%'.str_replace(['!', '%', '_'], ['!!', '!%', '!_'], mb_strtolower(trim($text))).'%';
        $query->where(function ($sub) use ($columns, $needle) {
            foreach ($columns as $column) {
                $sub->orWhereRaw("LOWER(COALESCE($column, '')) LIKE ? ESCAPE '!'", [$needle]);
            }
        });
    }
}
