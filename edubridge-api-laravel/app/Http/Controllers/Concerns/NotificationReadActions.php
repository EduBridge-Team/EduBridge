<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

trait NotificationReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        // Pagination is opt-in: installed clients retain the legacy full list.
        $paged = $request->query->has('limit') || $request->query->has('before_id') || $request->query->has('after_id');
        $paging = $paged ? Validator::make($request->query(), [
            'limit' => ['sometimes', 'required', 'integer', 'min:1', 'max:100'],
            'before_id' => ['sometimes', 'required', 'integer', 'min:1', 'missing_with:after_id'],
            'after_id' => ['sometimes', 'required', 'integer', 'min:0', 'missing_with:before_id'],
        ])->validate() : [];

        try {
            $query = DB::table('notifications')
                ->where('user_id', $user->id)
                ->select(
                    'id',
                    'user_id',
                    'title',
                    'message',
                    'message as body',
                    'type',
                    'is_read',
                    'created_at'
                );

            if ($request->query('unread')) {
                $query->where('is_read', false);
            }

            if (!$paged) {
                return response()->json(['notifications' => $query->orderByDesc('created_at')->orderByDesc('id')->get()]);
            }

            $limit = (int) ($paging['limit'] ?? 30);
            $delta = array_key_exists('after_id', $paging);
            if ($delta) {
                // Ascending deltas prevent skipping arrivals when more than one page accumulated.
                $query->where('id', '>', (int) $paging['after_id'])->orderBy('id');
            } else {
                if (isset($paging['before_id'])) {
                    $query->where('id', '<', (int) $paging['before_id']);
                }
                $query->orderByDesc('id');
            }
            $rows = $query->limit($limit + 1)->get();
            $hasMore = $rows->count() > $limit;
            $items = $rows->take($limit)->values();
            $lastId = $items->last()?->id;
            $count = DB::table('notifications')->where('user_id', $user->id)->where('is_read', false)->count();

            return response()->json([
                'notifications' => $items,
                'unread_count' => $count,
                'pagination' => [
                    'limit' => $limit,
                    'has_more' => $hasMore,
                    'next_before_id' => !$delta && $hasMore ? $lastId : null,
                    'next_after_id' => $delta ? ($lastId ?? (int) $paging['after_id']) : ($items->first()?->id ?? 0),
                ],
            ]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function unreadCount(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $count = DB::table('notifications')
                ->where('user_id', $user->id)
                ->where('is_read', false)
                ->count();

            return response()->json(['count' => $count]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
